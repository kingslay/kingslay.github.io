Object-c中的奇异代码

一、struct的用法

正常CGRect的创建方式是

CGRect rect1 = CGRectMake(0, 0, 12, 22);
CGRectMake是CoreGraphics提供的方法。如果没有这个全局方法的话，那要用下面这种写法了

struct CGRect rect2;
rect2.origin = CGPointZero;
rect2.size.width = 12;
rect2.size.height = 22;
这个是通用的struct的创建方法。但是这样还是比较麻烦的。 在网上有看到一种用法

CGRect rect3 = (CGRect){
                    .size.width = 12,
                    .size.height = 22,
                    .origin.x = 0,
                    .origin.y = 0
};
这是C99初始化语法。这样代码更直观了。还有一种更简洁的方式，但是就没有那么直观了

CGRect rect4 = { .origin = CGPointZero, 12, 22 };
CGRect rect5 = { 0, 0, 12, 22 };
二、statement expressions

昨晚在网上看了一篇文章.里面提供了一种新奇的写法

 CGRect rect6 = ({
    struct CGRect rect2;
    rect2.origin = CGPointZero;
    rect2.size.width = 22;
    rect2.size.height = 32;
    rect2;
}); 
This is a gcc extension called statement expressions, you can find the complete list of C extensions here .这种特性在Linux内核中常被用于宏的定义中