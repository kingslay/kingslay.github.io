# GPUImage3 源码解读

GPUImage是图像、视频处理框架，内置多种滤镜。支持自定义滤镜、相机实时滤镜处理等

## 一、版本

GPUImage 发展至今，演化出了不同的版本：

- [GPUImage](https://github.com/BradLarson/GPUImage)，基于 OpenGL ES 封装，使用 Objective-C 编写
- [GPUImage 2](https://github.com/BradLarson/GPUImage2)，基于 OpenGL ES 封装，使用 Swift 编写
- [GPUImage 3](https://github.com/BradLarson/GPUImage3)，基于 Metal 封装，使用 Swift 编写

## 二、核心协议

1、输入源 ImageSource

```swift
public protocol ImageSource {
    var targets:TargetContainer { get }
    func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt)
}

```

具体实现有：MovieInput、Camera、PictureInput

2、输出源ImageConsumer

```swift
public protocol ImageConsumer:AnyObject {
    var maximumInputs:UInt { get }
    var sources:SourceContainer { get }
    
    func newTextureAvailable(_ texture:Texture, fromSourceIndex:UInt)
}
```

具体实现有RenderView、PictureOutput

3、滤镜

```swift
public protocol ImageProcessingOperation: ImageConsumer, ImageSource {
}
```

因为滤镜是输入源，又是输出源,所以就可以使用链接调用的方式

```swift
camera --> operation --> renderView

infix operator --> : AdditionPrecedence
//precedencegroup ProcessingOperationPrecedence {
//    associativity: left
////    higherThan: Multiplicative
//}
@discardableResult public func --><T:ImageConsumer>(source:ImageSource, destination:T) -> T {
    source.addTarget(destination)
    return destination
}
```



## 三、核心代码

**generateRenderPipelineState** 通过传入的 device，vertexFunctionName 以及 fragmentFunctionName，来生成所需的 MTLRenderPipelineState(渲染管线)

**renderQuad** 是针对 MTLCommandBuffer 扩展的一个方法，专门用来处理渲染，即对应的渲染管线配置，指令提交等。它接收对应的配置项，比如 MTLRenderPipelineState 和 inputTextures，然后执行渲染操作，将结果绘制到 outputTexture 上。可以说，这是整个渲染操作的核心所在。

```swift
func generateRenderPipelineState(device:MetalRenderingDevice, vertexFunctionName:String, fragmentFunctionName:String, operationName:String) -> (MTLRenderPipelineState, [String:(Int, MTLDataType)]) { }

 func renderQuad(pipelineState:MTLRenderPipelineState, uniformSettings:ShaderUniformSettings? = nil, inputTextures:[UInt:Texture], useNormalizedTextureCoordinates:Bool = true, imageVertices:[Float] = standardImageVertices, outputTexture:Texture, outputOrientation:ImageOrientation = .portrait) { }
```

## 四、奇异代码

```swift
public class BrightnessAdjustment: BasicOperation {
    public var brightness:Float = 0.0 {
        didSet {
            uniformSettings["brightness"] = brightness
        }
    }
    public init() {
        super.init(fragmentFunctionName:"brightnessFragment", numberOfInputs:1)
        ({brightness = 0.0})()
    }
}

```



## 



