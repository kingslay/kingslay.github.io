# ClangFormat-Xcode 插件使用

1、安装插件[ClangFormat-Xcode](https://github.com/travisjeffery/ClangFormat-Xcode)

​	要自己为格式化命令设置快捷键,也可以设为保存的文件的时候就自动格式化

2、在用户根目录(~)下创建 .clang-format 文件。文件内容如下

``` yaml
AlignEscapedNewlinesLeft: true
AlignTrailingComments: true
AllowAllParametersOfDeclarationOnNextLine: false
AllowShortFunctionsOnASingleLine: false
AllowShortIfStatementsOnASingleLine: true
AllowShortLoopsOnASingleLine: false
BreakBeforeBinaryOperators: false
AlwaysBreakBeforeMultilineStrings: false
AlwaysBreakTemplateDeclarations: false
BinPackParameters: false
BreakBeforeBraces: Attach
BreakBeforeTernaryOperators: false
BreakConstructorInitializersBeforeComma: false
CommentPragmas: ''
ConstructorInitializerAllOnOneLineOrOnePerLine: false
ConstructorInitializerIndentWidth: 0
ContinuationIndentWidth: 0
ObjCSpaceAfterProperty: true
ObjCSpaceBeforeProtocolList: true
ColumnLimit: 500
IndentWidth: 4
TabWidth: 4
UseTab: Never
Language: Cpp
ObjCBlockIndentWidth: 4
IndentCaseLabels: true
KeepEmptyLinesAtTheStartOfBlocks: true
AllowShortBlocksOnASingleLine: false
```

​	可以把 .clang-format 文件提交到各自项目的根目录。保证项目的代码风格一致。

3、Clang Format的格式化方式选择用  File 

4、批量格式化文件

​	(1)先安装clang-format

``` shell
brew install clang-format
```

​	(2)到项目的目录里 执行	

``` shell
 ls */*[hm]  | xargs clang-format -i -style=file
```
5、xcode8的插件

​	因为苹果对xcode8进行签名了。所以之前的插件都不能用了。要改用苹果自己的插件sdk来进行开发插件。所以要换成用插件[XcodeClangFormat](https://github.com/mapbox/XcodeClangFormat) 

6、福利

​	[xcode8能用的推荐插件](https://kemchenj.github.io/2016/09/10/2016-09-10/)