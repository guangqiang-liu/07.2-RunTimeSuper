# 07.2-Runtime super关键字

在平时的开发过程中，我们经常会执行`[super xxx]`来调用父类的方法，但是我们很少会去关心`super`关键字的底层是如何实现的，接下来我们来看下`super`关键字底层实现原理，我们新建一个工程，然后创建`Person`类和`Student`类，Student类继承自Person类，示例代码如下：

`Person`类

```
@interface Person : NSObject

- (void)run;
@end


@implementation Person

- (void)run {
    NSLog(@"%s", __func__);
}
@end
```

`Student`类

```
@interface Student : Person

@end


@implementation Student

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"%@", [self class]); // Student
        NSLog(@"%@", [self superclass]); // Person
        
        NSLog(@"%@", [super class]); // Student
        NSLog(@"%@", [super superclass]); // Person
    }
    return self;
}

- (void)run {
    [super run];
    
    NSLog(@"%s", __func__);
}
@end
```

`main`函数：

```
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        Student *stu = [[Student alloc] init];
        [stu run];
    }
    return 0;
}
```

接下来我们执行命令`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 Student.m`将`Student.m`文件转换为底层c++文件，转换为底层的`run`方法代码如下：

```
static void _I_Student_run(Student * self, SEL _cmd) {
    ((void (*)(__rw_objc_super *, SEL))(void *)objc_msgSendSuper)((__rw_objc_super){(id)self, (id)class_getSuperclass(objc_getClass("Student"))}, sel_registerName("run"));

    NSLog((NSString *)&__NSConstantStringImpl__var_folders_lr_81gwkh751xzddx_ffhhb5_0m0000gn_T_Student_18b3ae_mi_0, __func__);
}
```

我们将`Studnnt`类的`run`方法进行简化如下：

```
- (void)run {
    [super run];
    
    /**
     结构体objc_super包含两个成员：
     self：消息接收者(receiver)
     class_getSuperclass(objc_getClass("Student"))：消息接收者的父类(super_class)
     */
    struct objc_super superStruct = {
        self,
        class_getSuperclass(objc_getClass("Student"))
    };
    
    objc_msgSendSuper(superStruct, sel_registerName("run"));
    
    NSLog(@"%s", __func__);
}
```

我们发现当我们在`run`函数中执行`[super run]`后，最终底层转换为`objc_msgSendSuper()`消息发送，我们通过底层源码看下`objc_msgSendSuper`函数的定义，查找路径`objc4 -> message.h -> objc_msgSendSuper`，具体底层函数定义如下：


```
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
 
OBJC_EXPORT id _Nullable
objc_msgSendSuper(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)
    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0, 2.0);
```

我们从源码`objc_msgSendSuper`函数定义可以看到，函数接受两个参数

* objc_super
* SEL

我们再来看下`objc_super`结构体底层定义如下：

```
/// Specifies the superclass of an instance. 

struct objc_super {
    /// Specifies an instance of a class.
    
    // 消息接收者
    __unsafe_unretained _Nonnull id receiver;

    /// Specifies the particular superclass of the instance to message. 
#if !defined(__cplusplus)  &&  !__OBJC2__
    /* For compatibility with old objc-runtime.h header */
    __unsafe_unretained _Nonnull Class class;
#else

	// 消息接收者的父类
    __unsafe_unretained _Nonnull Class super_class;
#endif
    /* super_class is the first class to search */
};
```

简化`objc_super`结构体如下：

```

/**
 从`objc_msgSendSuper`函数的注释可以看到结构体的两个成员含义:the instance of the class that is to receive the message and the superclass at which to start searching for the method implementation.
 */
 
struct objc_super {
    // receiver就是消息接收者 (the instance of the class that is to receive the message)
    __unsafe_unretained _Nonnull id receiver;

    // super_class就是消息接收者的父类 (官方解释：the superclass at which to start searching for the method implementation)
    __unsafe_unretained _Nonnull Class super_class;
};
```

通过`objc_super`底层定义，我们可以看到这个结构体也包含两个成员

* receiver
* super_class

我们通过`objc_msgSendSuper`函数底层定义的注释中可以查看到参数`objc_super`结构体中两个成员的具体含义和作用

> instance of the class that is to receive the message and the superclass at which to start searching for the method implementation


从上面注释我们了解到`receiver`就是消息的接受者(也就是方法调用者)，`superclass`就是指从父类开始查找方法

因此在`Student`的`init`初始化函数中打印结果如下：

```
- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"%@", [self class]); // Student
        NSLog(@"%@", [self superclass]); // Person
        
        NSLog(@"%@", [super class]); // Student
        NSLog(@"%@", [super superclass]); // Person
    }
    return self;
}
```

`class`和`superclass`函数的底层源码实现：

```
- (Class)class {
    // self为方法调用者，也就是消息接收者(receiver)，返回当前方法调用者的类对象
    return object_getClass(self);
}
```

```
- (Class)superclass {
    // self为方法调用者，也就是消息接收者(receiver)，返回当前方法调用者的父类对象
    return return self->superclass;
}
```


讲解示例Demo地址：[https://github.com/guangqiang-liu/07.2-RunTimeSuper]()


## 更多文章
* ReactNative开源项目OneM(1200+star)：**[https://github.com/guangqiang-liu/OneM](https://github.com/guangqiang-liu/OneM)**：欢迎小伙伴们 **star**
* iOS组件化开发实战项目(500+star)：**[https://github.com/guangqiang-liu/iOS-Component-Pro]()**：欢迎小伙伴们 **star**
* 简书主页：包含多篇iOS和RN开发相关的技术文章[http://www.jianshu.com/u/023338566ca5](http://www.jianshu.com/u/023338566ca5) 欢迎小伙伴们：**多多关注，点赞**
* ReactNative QQ技术交流群(2000人)：**620792950** 欢迎小伙伴进群交流学习
* iOS QQ技术交流群：**678441305** 欢迎小伙伴进群交流学习