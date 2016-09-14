//
//  CardScrollView.m
//  GCCardViewController
//
//  Created by 宫城 on 16/5/31.
//  Copyright © 2016年 宫城. All rights reserved.
//

#import "CardScrollView.h"

#define kGCRatio 0.8
#define kGCViewWidth CGRectGetWidth(self.frame)
#define kGCViewHeight CGRectGetHeight(self.frame)
#define kGCScrollViewWidth kGCViewWidth*kGCRatio

@interface CardScrollView ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, assign) NSInteger totalNumberOfCards;
@property (nonatomic, assign) NSInteger startCardIndex;
@property (nonatomic, assign) NSInteger currentCardIndex;

@end

@implementation CardScrollView

#pragma mark - initialize

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kGCScrollViewWidth, kGCViewHeight)];
    self.scrollView.center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    [self addSubview:self.scrollView];
    
    self.cards = [NSMutableArray array];
    self.startCardIndex = 0;
    self.currentCardIndex = 0;
    self.canDeleteCard = YES;
}

#pragma mark - public methods

- (void)loadCard {
    for (UIView *card in self.cards) {
        [card removeFromSuperview];
    }
    
    self.totalNumberOfCards = [self.cardDataSource numberOfCards];
    if (self.totalNumberOfCards == 0) {
        return;
    }
    
    [self.scrollView setContentSize:CGSizeMake(kGCScrollViewWidth*self.totalNumberOfCards, kGCViewHeight)];
    [self.scrollView setContentOffset:[self contentOffsetWithIndex:0]];
    
    for (NSInteger index = 0; index < (self.totalNumberOfCards < 4 ? self.totalNumberOfCards : 4); index++) {
        UIView *card = [self.cardDataSource cardReuseView:nil atIndex:index];
        card.center = [self centerForCardWithIndex:index];
        card.tag = index;
        [self.scrollView addSubview:card];
        [self.cards addObject:card];
        
        if (self.canDeleteCard) {
            UIPanGestureRecognizer *deleteGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(deleteCard:)];
            deleteGesture.minimumNumberOfTouches = 1;
            deleteGesture.maximumNumberOfTouches = 1;
            deleteGesture.delegate = self;
            [card addGestureRecognizer:deleteGesture];
        }
        
        [self.cardDelegate updateCard:card withProgress:1 direction:CardMoveDirectionNone];
    }
}

- (NSArray *)allCards {
    return self.cards;
}

- (NSInteger)currentCard {
    return self.currentCardIndex;
}

#pragma mark - private methods

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    [self.scrollView setContentOffset:[self contentOffsetWithIndex:index] animated:animated];
}

- (CGPoint)centerForCardWithIndex:(NSInteger)index {
    return CGPointMake(kGCScrollViewWidth*(index + 0.5), CGRectGetHeight(self.scrollView.frame)/2);
}

- (CGPoint)contentOffsetWithIndex:(NSInteger)index {
    return CGPointMake(kGCScrollViewWidth*index, 0);
}

- (NSInteger)indexMapperTag:(NSInteger)tag {
    for (NSInteger index = 0; index < self.cards.count; index++) {
        UIView *card = [self.cards objectAtIndex:index];
        if (card.tag == tag) {
            return index;
            break;
        }
    }
    return 0;
}

- (void)reloadCardWithIndex:(NSInteger)index {
    [self reuseDeleteCardWithIndex:index];
    if (index == 3) {
        self.currentCardIndex-=1;
    }
    self.totalNumberOfCards-=1;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.scrollView setContentSize:CGSizeMake(kGCScrollViewWidth*self.totalNumberOfCards, kGCViewHeight)];
        for (UIView *card in self.cards) {
            [self.cardDelegate updateCard:card withProgress:1 direction:CardMoveDirectionNone];
        }
    }];
}

- (void)deleteCard:(UIPanGestureRecognizer *)gesture {
    CGPoint translatedPoint = [gesture translationInView:gesture.view];
    CGPoint cardCenter = CGPointMake(gesture.view.center.x, kGCViewHeight/2);
    CGFloat progress = fabs(translatedPoint.y/(kGCViewHeight/2));
    if (gesture.state == UIGestureRecognizerStateChanged) {
        cardCenter.y+=translatedPoint.y;
        [gesture.view setCenter:cardCenter];
        gesture.view.layer.opacity = 1 - 0.2*progress;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [gesture velocityInView:gesture.view];
        if ((translatedPoint.y < 0 && progress >= 1.0) || (translatedPoint.y < 0 && fabs(velocity.y) > 500)) {
            [UIView animateWithDuration:0.3 animations:^{
                [gesture.view setCenter:CGPointMake(gesture.view.center.x, -kGCViewHeight/2)];
            } completion:^(BOOL finished) {
                [self reloadCardWithIndex:[self indexMapperTag:gesture.view.tag]];
                [self.cardDataSource deleteCardWithIndex:gesture.view.tag];
            }];
        } else {
            [UIView animateWithDuration:0.3 animations:^{
                [gesture.view setCenter:cardCenter];
                gesture.view.layer.opacity = 1.0;
            }];
        }
    }
}

- (void)reuseCardWithMoveDirection:(CardMoveDirection)moveDirection {
    BOOL isLeft = moveDirection == CardMoveDirectionLeft;
    UIView *card = nil;
    if (isLeft) {
        if (self.currentCardIndex > self.totalNumberOfCards - 3 || self.currentCardIndex < 2) {
            return;
        }
        card = [self.cards objectAtIndex:0];
        card.tag+=4;
    } else {
        if (self.currentCardIndex > self.totalNumberOfCards - 4 ||
            self.currentCardIndex < 1) {
            return;
        }
        card = [self.cards objectAtIndex:3];
        card.tag-=4;
    }
    card.center = [self centerForCardWithIndex:card.tag];
    [self.cardDataSource cardReuseView:card atIndex:card.tag];
    [self ascendingSortCards];
}

- (void)reuseDeleteCardWithIndex:(NSInteger)index {
    if (self.totalNumberOfCards <= 4) {
        [(UIView *)[self.cards objectAtIndex:index] removeFromSuperview];
        [self resetTagFromIndex:index];
        [self.cards removeObjectAtIndex:index];
        [self ascendingSortCards];
        return;
    }
    
    UIView *card = [self.cards objectAtIndex:index];
    NSInteger fromIndex = index;
    if (index == 0) {
        card.tag+=4;
        fromIndex = index - 1;
    } else if (index == 3) {
        card.tag-=4;
    } else {
        NSInteger lastTag = ((UIView *)[self.cards lastObject]).tag;
        NSInteger firstTag = ((UIView *)[self.cards firstObject]).tag;
        if (lastTag == self.totalNumberOfCards - 1) {
            card.tag = firstTag - 1;
        } else {
            card.tag = lastTag + 1;
            fromIndex = index - 1;
        }
    }
    card.center = [self centerForCardWithIndex:card.tag];
    [self ascendingSortCards];
    [self resetTagFromIndex:fromIndex];
    [self.cardDataSource cardReuseView:card atIndex:card.tag];
}

- (void)resetTagFromIndex:(NSInteger)index {
    [self.cards enumerateObjectsUsingBlock:^(UIView *card, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((NSInteger)idx > index) {
            card.tag-=1;
            [UIView animateWithDuration:0.3 animations:^{
                card.center = [self centerForCardWithIndex:card.tag];
            }];
        }
    }];
}

- (void)ascendingSortCards {
    [self.cards sortUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {
        return obj1.tag > obj2.tag;
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint translatedPoint = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:gestureRecognizer.view];
        if (fabs(translatedPoint.y) > fabs(translatedPoint.x)) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat orginContentOffset = self.currentCardIndex*kGCScrollViewWidth;
    CGFloat diff = scrollView.contentOffset.x - orginContentOffset;
    CGFloat progress = fabs(diff)/(kGCViewWidth*0.8);
    CardMoveDirection direction = diff > 0 ? CardMoveDirectionLeft : CardMoveDirectionRight;
    for (UIView *card in self.cards) {
        [self.cardDelegate updateCard:card withProgress:progress direction:direction];
    }
    
    if (fabs(diff) >= kGCScrollViewWidth*0.8) {
        self.currentCardIndex = direction == CardMoveDirectionLeft ? self.currentCardIndex + 1 : self.currentCardIndex - 1;
        [self reuseCardWithMoveDirection:direction];
    }
}

@end
