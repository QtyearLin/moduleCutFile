//
//  UzmoduleCutFile.m
//  UZApp
//
//  Created by tyearlin on 2017/8/22.
//  Copyright © 2017年 APICloud. All rights reserved.
//


#import "UzmoduleCutFile.h"
#import "UZAppDelegate.h"
#import "NSDictionaryUtils.h"

//文件切割成功回调flag
static const int CALLBACK_CUTFILE = 0x01;

@interface UzmoduleCutFile ()

<UIAlertViewDelegate>
{
    NSInteger _cbId;
    int _cutSize;

}
@end

@implementation UzmoduleCutFile

- (id)initWithUZWebView:(UZWebView *)webView_ {
    if (self = [super initWithUZWebView:webView_]) {
        
    }
    return self;
}

- (void)dispose {
    //do clean
}

/***
 *   切片入口
 */
- (void)cutFile:(NSDictionary *)paramDict {
    _cbId = [paramDict integerValueForKey:@"cbId" defaultValue:0];
     _cutSize = [paramDict intValueForKey:@"cutSize" defaultValue:4];
    Boolean test = [paramDict boolValueForKey:@"test" defaultValue:false];
    NSString* path = [paramDict stringValueForKey:@"path" defaultValue:nil];
    NSString *fullPath = [self getFullFile:path];
    if (fullPath){
        NSLog(@"文件绝对路径为：%@",fullPath);
        if (test) {
            NSString *message = [paramDict stringValueForKey:@"msg" defaultValue:nil];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alert show];
            
        } else{
            [self startCutFile:fullPath];
        }
        return;
    }
    NSLog(@"获取原始文件路径失败");
    
}

/***
 *   获取绝对路径
 */
- (NSString *)getFullFile:(NSString *)path {
    if (path) {
        NSLog(@"js传入文件路径为：%@",path);
        NSString *fullPath = [self getPathWithUZSchemeURL:path];
        NSLog(@"文件绝对路径为：%@",fullPath);
        return fullPath;
    }
    return nil;
}


/***
 *   开始切片
 */
-(void)startCutFile:(NSString*) path {
    //切片文件命名规则...
    NSLog(@"startCutFile");
    NSString *homePath = NSHomeDirectory();
    // 创建一个空数组
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSLog(@"沙盒目录:%@",homePath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cutFileDir = [homePath stringByAppendingPathComponent:@"CutVideos"];
    NSString *testPath = [homePath stringByAppendingPathComponent:@"a"];

    BOOL sucess = [fileManager createDirectoryAtPath:cutFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    if(sucess){
        NSLog(@"切片目录文件创建成功");
    }else{
        NSLog(@"切片目录文件创建失败");
        return;
    }
    NSLog(@"%@",cutFileDir);
       // 文件属性
    NSDictionary *attr = [fileManager attributesOfItemAtPath:testPath error:nil];
    // 如果这个文件或者文件夹不存在,或者路径不正确直接返回0;
    if (attr == nil) return ;
    int fileSize = [attr[NSFileSize] intValue];
    NSLog(@"原文件大小:%d",fileSize);
    int cutSize =_cutSize*1024*1024;
    NSInteger chunks = (fileSize/cutSize==0)?((int)(fileSize/cutSize)):((int)(fileSize/(cutSize) + 1));//cut file numbers
    NSLog(@"chunks = %ld",(long)chunks);
    // 将文件分片，读取每一片的数据：
    for (int i =0; i<chunks; i++) {
        //save to temp file
        NSString* cutFilePath = [self createSingleCutFile:testPath cutFileIndex:i cutFileSize:cutSize
                                           originFileSize:fileSize cutFileNumbers:chunks cutFileSaveDir:cutFileDir];
        if(cutFilePath) {
            [array addObject:cutFilePath];
        } else{
            [self cutCallBack:nil success:@"1" msg:@"文件切割失败"];
            return;
        }
        
    }
    //切割回调
    NSInteger count = [array count];
    for (int i = 0 ;i < count; i++) {
        NSLog(@"切割文件路径遍历如下：%@",[array objectAtIndex:i]);
    }
    [self cutCallBack:array success:@"0" msg:@"文件切割成功"];
    
}
/***
 *   切片回调 @code:0成功 1失败
 */
-(void) cutCallBack:(NSArray*) array success:(NSString*)code msg:(NSString*)msg{
    if (_cbId == CALLBACK_CUTFILE) {
        NSDictionary *ret = @{@"cutFiles":array,@"code":code,@"msg":msg};
        [self sendResultEventWithCallbackId:_cbId dataDict:ret errDict:nil doDelete:YES];
    }
    
}

-(NSString*)createSingleCutFile:(NSString*) path cutFileIndex:(int)i
                    cutFileSize:(int) cutSize
                 originFileSize:(int) fileSize
                 cutFileNumbers:(NSInteger) cutNumbers
                 cutFileSaveDir:(NSString*) saveDir {
    NSString *index = [NSString stringWithFormat:@"%d",i];
    NSString* cutFilePath = [saveDir stringByAppendingPathComponent:index];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL sucess = [fileManager createFileAtPath:cutFilePath contents:nil attributes:nil];
    if(sucess){
        NSLog(@"文切片件创建成功");
        //写文件准备
        //创建写文件的handle
        NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:cutFilePath];
        //从当前偏移量读取到文件的末尾
        NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
        NSData* data;
        [readHandle seekToFileOffset:cutSize * i];
        if (i==cutNumbers-1) {
            data = [readHandle readDataOfLength:fileSize];
        } else {
            data = [readHandle readDataOfLength:cutSize];
            
        }
        //[readHandles availableData];
        [writeHandle writeData:data];
        //关闭文件
        [readHandle closeFile];
        [writeHandle closeFile];
         NSLog(@"文件切片成功%@",cutFilePath);
        return cutFilePath;
        
    }else{
        NSLog(@"文件创建失败%d",i);
        return nil;
    }
    
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (_cbId > 0) {
        NSDictionary *ret = @{@"index":@(buttonIndex+1)};
        [self sendResultEventWithCallbackId:_cbId dataDict:ret errDict:nil doDelete:YES];
    }
}@end
