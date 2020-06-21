//
//  main.m
//  07.2-Runtime super关键字
//
//  Created by 刘光强 on 2020/2/8.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Student.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        Student *stu = [[Student alloc] init];
        [stu run];
    }
    return 0;
}
