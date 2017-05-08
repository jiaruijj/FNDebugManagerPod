//
//  FNDebugManager.m
//  FNMerchant
//
//  Created by JR on 16/8/5.
//  Copyright © 2016年 FeiNiu. All rights reserved.
//

#import "FNDebugManager.h"
#import "NSBundle+debugManager.h"

NSString *  const FNDomainTypeDidChangedNotification = @"com.feiniu.FNDomainType.change";

static NSString * const FNLastDomainTypeName = @"LastDomainType";

static NSString * const kBodyKey = @"body";
static NSString * const KAPIKey = @"wirelessAPI";

@interface FNDebugManager () <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, assign) BOOL enableDownloadAPI;
@property (nonatomic, strong) NSDictionary *apiDictionary;
@property (nonatomic, assign) NSInteger environmentType;

@property (nonatomic, strong) NSURLConnection *URLConnection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSArray *trustedCertificates;
@property (nonatomic, copy)   void(^requestResult)(BOOL success);

@end


@implementation FNDebugManager

+ (instancetype)shareManager
{
    static  FNDebugManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FNDebugManager alloc] init];
        [manager registerNotificationObserver];
        [manager updateApiDictionaryForEnvironmentChange];
    });
    return manager;
}

- (void)changeEviroment:(configUrlBlock)configUrlBlock{
    if (configUrlBlock) {
        self.configUrlBlock = configUrlBlock;
        self.domainURLString = configUrlBlock(self.domainType);
    }
}


- (void)configDomainType
{
#ifdef DEBUG
    self.domainType = FNDomainTypeBeta; //调试时随便改
#else
    self.defaultDomainType = FNDomainTypeOnline; //不要修改成online，默认第一次启动环境
    [self readLastConfifegFromUserDeafealt]; // 读取上一次保存的环境
#endif
}

- (void)configCid:(NSString *)cid deviceToken:(NSString *)deviceToken
{
    self.cid = cid;
    self.deviceToken = deviceToken;
}


- (void)readLastConfifegFromUserDeafealt
{
    // 从userdefault中读取上次保存的环境
    FNDomainType lastType = [[[NSUserDefaults standardUserDefaults] valueForKey:FNLastDomainTypeName] intValue];
    if (lastType == FNDomainTypeNone) {
        // 如果是第一次启动则走默认环境
        lastType = [self defaultDomainType];
    }
    [self setDomainType:lastType]; // 设置当前domainType为之前使用的domainType
}



- (BOOL)saveChanges{
    // 设置完成之后保存信息到userdefault中
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *domainTypeNum = [NSNumber numberWithInt:_domainType];
    [userDefault setValue:domainTypeNum forKey:FNLastDomainTypeName];
    
    if ([userDefault synchronize]) {
        [self postDomainTypeDidChangeNotification];
        return YES;
    }
    return NO;
}


- (void)saveEviromentChnageSuccess:(saveSuccessBlock)success failure:(saveFailureBlock)failure
{
    if (success) {
        self.saveSuccessBlock = success;
        
    }
    if (failure) {
        self.saveFailureBlock = failure;
    }
}

- (void)domainTypeResult: (FNDomainType)domainType  result:(void(^)(BOOL success))block
{
    BOOL result = [self saveChanges];
    if (block) {
        block(result);
    }
}

//保存成功后发送通知
- (void)postDomainTypeDidChangeNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:FNDomainTypeDidChangedNotification object:@(self.domainType)];
}



#pragma mark - setter&&getter

- (void)setDomainType:(FNDomainType)domainType
{
    if (_domainType == domainType) {
        return;
    }
    _domainType = domainType;
    
    [self saveChanges];
}

- (FNDomainType)defaultDomainType{
    if (_defaultDomainType) {
        return _defaultDomainType;
    }
    return [self onlineClientDomainType];
}

- (FNDomainType)fristActiveDomainType{
    return FNDomainTypeBeta;
}

- (FNDomainType)onlineClientDomainType{
    return FNDomainTypeOnline;
}



#pragma mark =======================

- (FNDomainType) currentEnv {
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:FNLastDomainTypeName];
    if (number) {
        return [number integerValue];
    }
    return FNDomainTypeOnline;
}

- (NSString *) currentEnvString {
    switch ([self currentEnv]) {
        case FNDomainTypeNone:
            return @"无环境";
            break;
        case FNDomainTypeDev:
            return @"开发环境";
            break;
        case FNDomainTypeBeta:
            return @"测试环境";
            break;
        case FNDomainTypePreview:
            return @"预览环境";
            break;
        case FNDomainTypeOnline:
            return @"线上环境";
            break;
        default:
            break;
    }
    return @"";
}





#pragma mark - Public Method

+ (void)requstEnvironment
{
    [[FNDebugManager shareManager] requstEnvironment];
}

+ (void)requestAPIsResult:(void (^)(BOOL))result {
    [FNDebugManager shareManager].requestResult = result;
    [self requstEnvironment];
}

+ (void)setEnableDownloadAPI:(BOOL)flag {
    [[FNDebugManager shareManager] setEnableDownloadAPI:flag];
}

+ (void)changeEnvironment:(FNDomainType)environment
{
    FNDebugManager *shareInstance = [FNDebugManager shareManager];
    // 保存新的环境
    shareInstance.environmentType = environment;
    if (shareInstance.configUrlBlock) {
        shareInstance.domainURLString = shareInstance.configUrlBlock(environment);
    }
    // 更新 保存java API 的字典
    [shareInstance updateApiDictionaryForEnvironmentChange];
}

+ (void)clearDocumentFile
{
    NSString *path = [[FNDebugManager shareManager] filePath];
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if (!deleted) {
        DLog(@"删除缓存文件夹失败");
    }
}

#pragma mark - Get FullPath With Key
+ (NSString *)URLStringForPath:(NSString *)path
{
    if (![FNDebugManager shareManager].enableDownloadAPI) {
        return nil;
    }
    
    
    NSString *fullJavaPath = [[FNDebugManager shareManager] fullURLStringWithJavaPath:path];
    
    // NSAssert(fullJavaPath.length > 0, @"未找到相应下发API key:%@", path);
    return fullJavaPath ? fullJavaPath : nil;
}

- (NSString *)fullURLStringWithJavaPath:(NSString *)path
{
    if (!path) {
        return nil;
    }
    // 根据 path 查询是否存在对应的下发URL
    NSString *fullURLString = [[FNDebugManager shareManager].apiDictionary objectForKey:path];
    
    
    
    return fullURLString.length > 0 ? fullURLString : path;
}

#pragma mark - Private Method
- (void)requstEnvironment
{
    DLog(@"*******************  requstEnvironment ********************************");
    NSURL *url = [NSURL URLWithString:self.domainURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.TLSMaximumSupportedProtocol = kTLSProtocol1;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error) {
                                          if (data != nil) {
                                              [weakSelf handleSessionTaskCompletionData:data response:response error:error];
                                          }else{
                                              [weakSelf runResultWithSuccess:NO];
                                          }
                                          weakSelf.requestResult = nil;
                                      }];
    [dataTask resume];
}

- (void)handleSessionTaskCompletionData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error
{
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    DLog(@"requestAPI Response : %@",jsonDic);
    if ([jsonDic isKindOfClass:[NSDictionary class]]) {
        NSDictionary *apiContentDic = jsonDic[kBodyKey][KAPIKey];
        if (apiContentDic.count > 0) {
            [self saveEnvironmentWithDictionary:jsonDic];
            self.apiDictionary = apiContentDic;
            [self runResultWithSuccess:YES];
            return;
        }
    }
    [self runResultWithSuccess:NO];
}



- (void)addTrustedCertificates:(NSString *)sslFileName {
    
    NSString *cerPath = sslFileName?[[NSBundle mainBundle] pathForResource:sslFileName ofType:nil]:[[NSBundle debugManagerBundle] pathForResource:@"fn_ssl.cer" ofType:nil];
    
    DLog(@"cerPath ======== %@",cerPath);
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(cerData));
    self.trustedCertificates = @[CFBridgingRelease(certificate)];
    
}


- (void)runResultWithSuccess:(BOOL)success {
    if (self.requestResult) {
        self.requestResult(success);
    }
}

- (BOOL)saveEnvironmentWithDictionary:(NSDictionary *)jsonDic {
    return [jsonDic writeToFile:[self filePath] atomically:YES];
}

- (void)updateApiDictionaryForEnvironmentChange {
    _apiDictionary = [self apiDictionaryForEnvironmentType:_environmentType];
}

- (NSDictionary *)apiDictionaryForEnvironmentType:(NSInteger)type
{
    NSString *filePath = [self filePath];
    NSDictionary *apiDictionary = [self apiDictionaryForPath:filePath];
    if (!apiDictionary) {
        NSString *defaultFilePath = [[NSBundle mainBundle] pathForResource:[self fileName] ofType:@"plist"];
        apiDictionary = [self apiDictionaryForPath:defaultFilePath];
    }
    return apiDictionary;
}

- (NSDictionary *)apiDictionaryForPath:(NSString *)path
{
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSDictionary *apiDictionary = jsonDictionary[kBodyKey][KAPIKey];
    return apiDictionary;
}

#pragma mark -session delegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    //1)获取trust object
    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    SecTrustResultType result;
    
    //注意：这里将之前导入的证书设置成下面验证的Trust Object的anchor certificate
    SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)self.trustedCertificates);
    
    //2)SecTrustEvaluate会查找前面SecTrustSetAnchorCertificates设置的证书或者系统默认提供的证书，对trust进行验证
    OSStatus status = SecTrustEvaluate(trust, &result);
    if (status == errSecSuccess &&
        (result == kSecTrustResultProceed ||
         result == kSecTrustResultUnspecified))
    {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    }
    
    if (self.environmentType == FNDomainTypeDev || self.environmentType == FNDomainTypeBeta) {
        credential = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
        disposition = NSURLSessionAuthChallengeUseCredential;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    __block NSURLCredential *credential = nil;
    
    //1)获取trust object
    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    SecTrustResultType result;
    
    //注意：这里将之前导入的证书设置成下面验证的Trust Object的anchor certificate
    SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)self.trustedCertificates);
    
    //2)SecTrustEvaluate会查找前面SecTrustSetAnchorCertificates设置的证书或者系统默认提供的证书，对trust进行验证
    OSStatus status = SecTrustEvaluate(trust, &result);
    if (status == errSecSuccess &&
        (result == kSecTrustResultProceed ||
         result == kSecTrustResultUnspecified))
    {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    }
    
    if (self.environmentType == FNDomainTypeDev || self.environmentType == FNDomainTypeBeta) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        disposition = NSURLSessionAuthChallengeUseCredential;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    DLog(@"didCompleteWithError = %@",error);
}
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    DLog(@"didBecomeInvalidWithError = %@",error);
    
}
#pragma mark- Application Notification

- (void)applicationDidBeacomeActive:(NSNotification *)notification {
    if (!self.enableDownloadAPI) {
        return;
    }
    [self updateApiDictionaryForEnvironmentChange];// 每次去读取最新
    [FNDebugManager requstEnvironment];// 从服务器获取最新api
}

- (void)registerNotificationObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBeacomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                              forKeyPath:UIApplicationDidBecomeActiveNotification];
}

#pragma mark - Getter

- (NSDictionary *)apiDictionary {
    if (_apiDictionary) {
        return _apiDictionary;
    }
    _apiDictionary = [self apiDictionaryForEnvironmentType:_environmentType];
    return _apiDictionary;
}



- (NSString *)filePath
{
    NSString *fileName = [self fileName];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask,YES);
    NSString *documentPath = [documentPaths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
    NSString *filePathWithExtension = [filePath stringByAppendingPathExtension:@"plist"];
    return filePathWithExtension;
}

- (NSString *)fileName
{
    NSString *fileName = nil;
    switch (_environmentType) {
        case FNDomainTypeNone:
            fileName = @"APIInfomationOnline";
            break;
        case FNDomainTypeDev:
            fileName = @"APIInfomationDev";
            break;
        case FNDomainTypeBeta:
            fileName = @"APIInfomationBeta";
            break;
        case FNDomainTypePreview:
            fileName = @"APIInfomationPreview";
            break;
        case FNDomainTypeOnline:
            fileName = @"APIInfomationOnline";
            break;
        default:
            break;
    }
    return fileName;
}

@end

