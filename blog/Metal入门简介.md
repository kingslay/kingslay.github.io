# Metal入门简介

​	Metal 是用于操作GPU的，为了要让GPU为你工作，你必须发出一些命令。你的App可以让GPU执行绘图，并行计算，资源管理。Metal和GPU可以理解为 客户端 — 服务器模式。

##  一、流程

​	为了要将命令发送到GPU。首先要通过设备（MTLDevice）创建命令队列（MTLCommandQueue）。然后每次渲染的时候通过命令队列创建命令缓冲区（MTLCommandBuffer），通过命令缓冲区创建命令编码器（ MTLCommandEncoder），提交命令缓冲区（commit）

## 二、MTLDevice

​	一个MTLDevice对象代表一个可以执行命令的GPU。MTLDevice协议具有创建新命令队列，从内存分配缓冲区，创建纹理以及查询设备功能的方法。可以调用MTLCreateSystemDefaultDevice方法来获得MTLDevice。

## 三、命令队列（MTLCommandQueue）

（1）命令队列会有很长的生命周期，一般是在类初始化的时候，就初始化。

（2）MTLCommandQueue由device创建，通过`makeCommandQueue`方法或`makeCommandQueue(maxCommandBufferCount: Int)`方法来创建。maxCommandBufferCount用来限制队列的长度。

（3）通过MTLCommandQueue可以创建MTLCommandBuffer。允许同时创建多个命令缓冲区，多线程进行编码。

（3）MTLCommandQueue是线程安全的，保证指令（MTLCommandBuffer）有序地发送到GPU；

## 四、命令缓冲区（MTLCommandBuffer）

（1）MTLCommandBuffer是一次性对象，不支持重用。在每次渲染的时候，都会重新创建 

（2）通过MTLCommandEncoder可以创建4种CommandEncoder

（3）对于同一个commandBuffer，只有调用CommandEncoder的结束编码，才能进行下一个CommandEncoder的创建

（3）等所有的CommandEncoder都结束编码之后通过commit 方法把所有的命令提交到 MTLCommandQueue

## 五、命令编码器（MTLCommandEncoder）

（1）MTLCommandEncoder是一次性对象，不支持重用。在每次渲染的时候，都会重新创建

（2）分为四种类型

​	MTLRenderCommandEncoder：图形渲染命令

​	MTLComputeCommandEncoder： 主要对数据并行计算处理

​	MTLBlitCommandEncoder：缓冲区和纹理拷贝操作命令

​	MTLParallelRenderCommandEncoder：并行图形渲染命令

（3）调用`endEncoding` 来结束命令编码