//
//  Student.m
//  07.2-Runtime super关键字
//
//  Created by 刘光强 on 2020/2/8.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import "Student.h"
#import <objc/runtime.h>

/**
 从`objc_msgSendSuper`函数的注释可以看到结构体的两个成员含义
 
  the instance of the class that is to receive the message and the superclass at which to start searching for the method implementation.
 */
struct objc_super {
    // receiver就是消息接收者 (the instance of the class that is to receive the message)
    __unsafe_unretained _Nonnull id receiver;

    // super_class就是消息接收者的父类 (the superclass at which to start searching for the method implementation)
    __unsafe_unretained _Nonnull Class super_class;
};

/**
 * Sends a message with a simple return value to the superclass of an instance of a class.
 *
 * @param super A pointer to an \c objc_super data structure. Pass values identifying the
 *  context the message was sent to, including the instance of the class that is to receive the
 *  message and the superclass at which to start searching for the method implementation.
 * @param op A pointer of type SEL. Pass the selector of the method that will handle the message.
 * @param ...
 *   A variable argument list containing the arguments to the method.
 *
 * @return The return value of the method identified by \e op.
 *
 * @see objc_msgSend
 */
//OBJC_EXPORT id _Nullable
//objc_msgSendSuper(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)
//    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0, 2.0);

@implementation Student

// NSObject基类底层`class`函数的伪代码实现
- (Class)class {
    // self为方法调用者，也就是消息接收者(receiver)，返回当前方法调用者的类对象
    return object_getClass(self);
}

// NSObject基类底层`superclass`函数的伪代码实现
- (Class)superclass {
    // self为方法调用者，也就是消息接收者(receiver)，返回当前方法调用者的父类对象
    return class_getSuperclass(object_getClass(self));
}

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"-----");
        NSLog(@"%@", [self class]); // Student
        NSLog(@"%@", [self superclass]); // Person
        
        NSLog(@"%@", [super class]); // Student
        NSLog(@"%@", [super superclass]); // Person
    }
    return self;
}

- (void)run {
    [super run];
    
    /**
     结构体objc_super包含两个成员：
     self：就是消息接收者(receiver)
     class_getSuperclass(objc_getClass("Student"))：就是消息接收者的父类(super_class)
     */
    struct objc_super superStruct = {
        self,
        class_getSuperclass(objc_getClass("Student"))
    };
    
//    objc_msgSendSuper(superStruct, sel_registerName("run"));
    
    NSLog(@"%s", __func__);
}
@end
