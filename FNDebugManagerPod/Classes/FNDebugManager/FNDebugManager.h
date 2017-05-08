//
//  FNDebugManager.h
//  FNMerchant
//
//  Created by JR on 16/8/5.
//  Copyright © 2016年 FeiNiu. All rights reserved.
//

#import <UIKit/UIKit.h>


#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#define POD_BUNDLE [NSBundle bundleForClass:[self class]]


#ifdef DEBUG
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...)
#endif

@class FNdomainConfigModel;
/**
 * 环境类型
 */
typedef NS_ENUM(NSInteger, FNDomainType) {
    FNDomainTypeNone,           // 没有环境
    FNDomainTypeDev,            // 开发环境
    FNDomainTypeBeta,           // 测试环境
    FNDomainTypePreview,        // 预览环境
    FNDomainTypeOnline,         // 线上环境
};

typedef void(^saveSuccessBlock)();
typedef void(^saveFailureBlock)();

typedef NSString *(^configUrlBlock)(FNDomainType domainType);

/** 环境切换的通知 */
extern NSString * FNChangeEnvironmentNotificationName;
/** domain地址改变的 Notification */
extern NSString * const FNDomainTypeDidChangedNotification;


@interface FNDebugManager : NSObject


/**
 *  设置当前环境
 */
@property (nonatomic, assign) FNDomainType domainType;
/**
 *  默认的启动环境 如果不配置那么为 online
 */
@property (nonatomic, assign) FNDomainType defaultDomainType;
/**
 *  是否是上线,优先级最高
 */
@property (nonatomic, assign, readonly) BOOL isOnlineClient;

@property (nonatomic, copy) NSString *cid;
@property (nonatomic, copy) NSString *deviceToken;
//XMPP服务器 域名
@property (nonatomic, copy) NSString *hostName;

@property (nonatomic, copy) saveSuccessBlock saveSuccessBlock;
@property (nonatomic, copy) saveFailureBlock saveFailureBlock;
@property (nonatomic, copy) configUrlBlock configUrlBlock;

@property (nonatomic, copy) NSString *domainURLString;





/**
 *  单例
 */
+ (instancetype)shareManager;

/**
 *  根据当前环境配置各个环境的Url
 */
- (void)changeEviroment:(configUrlBlock)configUrlBlock;

/**
 *  回调成功的状态
 *
 */
- (void)domainTypeResult:(FNDomainType)domainType  result:(void(^)(BOOL success))result;

/**
 *  配置当前环境根据debug和release
 */
- (void)configDomainType;

/**
 *  设置debug界面的cid和deviceToken
 *
 *  @param cid
 *  @param deviceToken
 */
- (void)configCid:(NSString *)cid deviceToken:(NSString *)deviceToken;

/**
 *  添加证书,调用此方法即代表是https请求,
 *
 *  @param sslFileName 为证书名称,为nil时为fn_ssl.cer证书
 */
- (void)addTrustedCertificates:(NSString *)sslFileName;


/**
 *  保存环境
 *
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)saveEviromentChnageSuccess:(saveSuccessBlock)success failure:(saveFailureBlock)failure;


/**
 *  返回当前的环境类型，具体的逻辑判断，由业务方进行逻辑处理
 *
 */
- (FNDomainType) currentEnv;

/**
 *  当前环境值
 *
 *  @return 当前环境的字符串，用于输出
 */
- (NSString *) currentEnvString;

/**
 * 读取最后一次配置的domain信息
 */
- (void)readLastConfifegFromUserDeafealt;

/**
 * 请求 java api 数据
 */
+ (void)requstEnvironment;

/**
 *  请求API带状态值
 *
 */
+ (void)requestAPIsResult:(void(^)(BOOL success))result;

/**
 *  是否使用下发的 API YES 为使用
 */
+ (void)setEnableDownloadAPI:(BOOL)flag;

/**
 *  改变环境
 */
+ (void)changeEnvironment:(FNDomainType)environment;

/**
 *  取得下发的API文件路径
 */
+ (NSString *)URLStringForPath:(NSString *)path;

/**
 *  清理缓存
 */
+ (void)clearDocumentFile;


@end






