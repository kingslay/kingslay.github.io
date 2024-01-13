# WWDC学习笔记

## 一、What's New in Photos APIs

[https://developer.apple.com/videos/play/wwdc2017/505/](https://developer.apple.com/videos/play/wwdc2017/505/)	

1、UIImagePickerControllerImageURLExportPreset

UIImagePickerController增加属性imageExportPreset。

```objective-c
typedef NS_ENUM(NSInteger, UIImagePickerControllerImageURLExportPreset) {
    UIImagePickerControllerImageURLExportPresetCompatible = 0,//如果原图是用heif存储的话。那就会转为jpeg。这是默认值
    UIImagePickerControllerImageURLExportPresetCurrent//不进行转化
} NS_AVAILABLE_IOS(11_0) __TVOS_PROHIBITED;
```

2、UIImagePickerControllerQualityTypeMedium

UIImagePickerController增加属性videoExportPreset 来改变视频的质量

3、支持从UIImagePickerController获取PHAsset

```
public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
  if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset { 
    print(asset)
  } 
}
```

4、Large Photo Libraries for Testing

提供了一个iOS项目帮助开发者生成大量的图片

https://developer.apple.com/sample-code/wwdc/2017/Creating-Large-Photo-Libraries-for-Testing.zip



## 二、Image Editing with Depth

[https://developer.apple.com/videos/play/wwdc2017/508/](https://developer.apple.com/videos/play/wwdc2017/508/)

km上有一篇文章介绍的非常的详细 

http://km.oa.com/group/25894/articles/show/307375



### 三、What's New in MapKit

[https://developer.apple.com/videos/play/wwdc2017/237/](https://developer.apple.com/videos/play/wwdc2017/237/)

1、独立出MKUserTrackingButton，MKScaleView，MKCompassButton。方便开发者进行定制布局

2、增加MKMarkerAnnotationView 这个新的类型

![屏幕快照 2017-06-16 11.51.46](/Users/kintan/Public/腾讯/文档/屏幕快照 2017-06-16 11.51.46.png)

3、增加displayPriority 用来控制Annotation的优先级

```swift
extension MKFeatureDisplayPriority {

    @available(iOS 11.0, *)
    public static let required: MKFeatureDisplayPriority

    @available(iOS 11.0, *)
    public static let defaultHigh: MKFeatureDisplayPriority

    @available(iOS 11.0, *)
    public static let defaultLow: MKFeatureDisplayPriority
}
```

4、MKMapType增加mutedStandard 这个类型

mutedStandard会隐藏地图上的一些信息

![屏幕快照 2017-06-16 14.47.07](/Users/kintan/Public/腾讯/文档/屏幕快照 2017-06-16 14.47.07.png)



## 四、Understanding Undefined Behavior

[https://developer.apple.com/videos/play/wwdc2017/407/](https://developer.apple.com/videos/play/wwdc2017/407/)

1、Undefined Behavior Sanitizer.

检查代码里面有不符合标准的写法

for example:

- Using misaligned or null pointer
- Signed integer overflow
- Conversion to, from, or between floating-point types which would overflow the destination

建议把Analyze During 'Build' 选项设置为true



2、Main Thread Checker

检查是否在主线程更新UI。支持Swfit和Object-C。实现原理就是动态替换方法的实现。

![屏幕快照 2017-06-16 16.48.10](/Users/kintan/Public/腾讯/文档/屏幕快照 2017-06-16 16.48.10.png)



## 五、StoreKit

[https://developer.apple.com/videos/play/wwdc2017/303/](https://developer.apple.com/videos/play/wwdc2017/303/)

[https://developer.apple.com/videos/play/wwdc2017/305/](https://developer.apple.com/videos/play/wwdc2017/305/)

1、Promote in-app purchases in the App Store

在iTunes Connect进行设置。并且实现下面的方法

```objective-c
// Sent when a user initiates an IAP buy from the App Store
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product NS_SWIFT_NAME(paymentQueue(_:shouldAddStorePayment:for:)) NS_AVAILABLE_IOS(11_0);

```

2、Server Notifications

在iTunes Connect登记接口。当有下列行为产生的时候，就会通过http post到服务器。这个通知存在失败的可能。

![屏幕快照 2017-06-21 16.23.18](/Users/kintan/Public/腾讯/文档/屏幕快照 2017-06-21 16.23.18.png)

并且Server Notifications不再区分正式环境和测试环境了。是通过environment key in payload 来进行区分正式环境还是测试环境。

3、返回的receipt信息增加了以下字段

![屏幕快照 2017-06-21 20.45.56](/Users/kintan/Public/腾讯/文档/屏幕快照 2017-06-21 20.45.56.png)

4、自动订阅的试用期没有订阅周期的限制了

![屏幕快照 2017-06-22 11.08.12](/Users/kintan/Public/腾讯/文档/屏幕快照 2017-06-22 11.08.12.png)





