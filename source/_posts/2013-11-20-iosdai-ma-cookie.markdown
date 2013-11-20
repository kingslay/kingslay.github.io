---
layout: post
title: "IOS代码 cookie"
date: 2013-11-20 23:04
comments: true
categories:
---
1、想点击UIViewController的任意地方，就可以dismiss keyboard,最简单的办法就是在VC中override以下方法:
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


