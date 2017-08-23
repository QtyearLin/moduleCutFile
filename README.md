# moduleCutFile
apicloud  iOS 大文件切片模块测试代码
！！！！！注意：
由于ios沙盒机制 
测试时需要把视频文件（命名为a(全名)拖入沙盒目录下（测试包中module代码已设置path= 沙盒路径+ 文件（需要明名为a)，）
//startCutFile 方法中的  NSString *testPath = [homePath stringByAppendingPathComponent:@"a"];
然后直接运行UzApp即可
