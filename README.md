# GCCardScrollView

## Introduction

This is animation is imitate iOS7 background preview animation, if you have more than 4 cards,it will reues card,and it can delete card

## Gif

![](https://github.com/Yuzeyang/GCCardViewController/raw/master/GCCardViewController.gif)

## how to use

1.add card scroll view

```objective-c
self.cardScrollView = [[CardScrollView alloc] initWithFrame:self.view.frame];
self.cardScrollView.cardDelegate = self;
self.cardScrollView.cardDataSource = self;
[self.view addSubview:self.cardScrollView];
```

2.update card when scrolling

```objective-c
- (void)updateCard:(UIView *)card withProgress:(CGFloat)progress direction:(CardMoveDirection)direction;
```

3.set cards number

```objective-c
- (NSInteger)numberOfCards;
```

4.reuse card

```objective-c
- (UIView *)cardReuseView:(UIView *)reuseView atIndex:(NSInteger)index;
```

5.delete card,this is optional

```objective-c
- (void)deleteCardWithIndex:(NSInteger)index;
```

