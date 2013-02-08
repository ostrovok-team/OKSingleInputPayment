//
//  OKSingleInputPayment.m
//  SingleInputPayment
//
//  Created by Ryan Romanchuk on 2/6/13.
//  Copyright (c) 2013 Ryan Romanchuk. All rights reserved.
//

#import "OKSingleInputPayment.h"
#import "CreditCardValidation.h"

@interface OKSingleInputPayment() {
    CGFloat maximumFontForCardNumber;
    CGFloat maximumFontForFields;

}
@property (strong, nonatomic) UITextField *cardNumberTextField;
@property (strong, nonatomic) UITextField *expirationTextField;
@property (strong, nonatomic) UITextField *cvcTextField;
@property (strong, nonatomic) UITextField *zipTextField;
@property (strong, nonatomic) UILabel *lastFourLabel;



@property (strong, nonatomic) NSString *trimmedNumber;
@property (strong, nonatomic) NSString *lastFour;
@property NSInteger minYear;
@property NSInteger maxYear;

@property (strong, nonatomic) UIImageView *containerView;
@property (strong, nonatomic) UIImageView *leftCardView;

@property (strong, nonatomic) UITextField *activeTextField;


@property OKCardType displayingCardType;
@property OKPaymentStep paymentStep;

@property BOOL ccNumberInvalid;

@property (strong, nonatomic) UIToolbar *accessoryToolBar;

@end

@implementation OKSingleInputPayment

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit:frame];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if(self = [super initWithCoder:aDecoder])
    {
        [self commonInit:self.frame];
    }
    return self;
}


- (void)commonInit:(CGRect)frame {
    self.defaultFont = [UIFont fontWithName:@"Helvetica" size:28];
    self.defaultFontColor = [UIColor blackColor];
    
    self.includeZipCode = YES;
    self.paymentStep = OKPaymentStepCCNumber;
    self.displayingCardType = OKCardTypeUnknown;
    _cardType = OKCardTypeUnknown;
    self.monthPlaceholder = @"mm";
    self.yearPlaceholder = @"yy";
    self.monthYearSeparator = @"/";
    self.cvcPlaceholder = @"cvc";
    self.zipPlaceholder = @"55128";
    self.numberPlaceholder = @"4111 1111 1111 1111";
    self.accessoryToolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 44)];
    [self setupAccessoryToolbar];
    [self updatePlaceholders];
    
    
    NSDateComponents *yearComponent = [[NSDateComponents alloc] init];
    yearComponent.year = 20;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDate *future = [theCalendar dateByAddingComponents:yearComponent toDate:[NSDate date] options:0];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yy"];
    self.minYear = [[formatter stringFromDate:date] integerValue];
    self.maxYear = [[formatter stringFromDate:future] integerValue];
       
    UIImage *background = [[UIImage imageNamed:@"field_cell"] resizableImageWithCapInsets:(UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0))];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.image = background;
    self.containerView = imageView;
    [self addSubview:self.containerView];
    
    
    self.leftCardView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credit_card_icon"]];
    self.leftCardView.backgroundColor = [UIColor blueColor];
    [self.leftCardView setFrame:CGRectMake(10, (self.frame.size.height / 2) - (self.leftCardView.frame.size.height/2), self.leftCardView.frame.size.width, self.leftCardView.frame.size.height)];
    
    int padding = 5;
    self.cardNumberTextField = [[UITextField alloc] initWithFrame:CGRectMake((self.leftCardView.frame.origin.x + self.leftCardView.frame.size.width) + padding, (self.frame.size.height / 2) - ((self.frame.size.height * 0.9) /2), self.frame.size.width - ((self.leftCardView.frame.origin.x + self.leftCardView.frame.size.width) + padding) - 5, self.frame.size.height * 0.9)];
    [self.numberPlaceholder sizeWithFont:self.defaultFont minFontSize:self.cardNumberTextField.minimumFontSize actualFontSize:&maximumFontForCardNumber forWidth:self.cardNumberTextField.frame.size.width lineBreakMode:NSLineBreakByClipping];

    self.cardNumberTextField.backgroundColor = [UIColor yellowColor];
    self.cardNumberTextField.font = [self fontWithNewSize:self.defaultFont newSize:maximumFontForCardNumber];
    self.cardNumberTextField.delegate = self;
    self.cardNumberTextField.adjustsFontSizeToFitWidth = YES;
    self.cardNumberTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberTextField.inputAccessoryView = self.accessoryToolBar;
    [self.cardNumberTextField addTarget:self action:@selector(cardNumberTextFieldValueChanged) forControlEvents:UIControlEventEditingChanged];
    self.cardNumberTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    [self addSubview:self.cardNumberTextField];
    [self addSubview:self.leftCardView];
    
    float availSpace = self.frame.size.width - ((self.leftCardView.frame.origin.x + self.leftCardView.frame.size.width) + (padding * 4));
    float widthPerField = availSpace / 4;
    
    [@"12345" sizeWithFont:self.defaultFont minFontSize:self.cardNumberTextField.minimumFontSize actualFontSize:&maximumFontForFields forWidth:widthPerField lineBreakMode:NSLineBreakByClipping];
    self.lastFourLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.leftCardView.frame.origin.x + self.leftCardView.frame.size.width) + padding, self.cardNumberTextField.frame.origin.y, widthPerField, self.cardNumberTextField.frame.size.height)];
    self.lastFourLabel.backgroundColor = [UIColor greenColor];
    self.lastFourLabel.hidden = YES;
    self.lastFourLabel.font = [self fontWithNewSize:self.defaultFont newSize:maximumFontForFields];
    self.lastFourLabel.adjustsFontSizeToFitWidth = YES;
    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previous:)];
    [self.lastFourLabel addGestureRecognizer:tg];
    self.lastFourLabel.userInteractionEnabled = YES;
    [self addSubview:self.lastFourLabel];
    
    self.expirationTextField = [[UITextField alloc] initWithFrame:CGRectMake((self.lastFourLabel.frame.origin.x + self.lastFourLabel.frame.size.width) + padding, self.cardNumberTextField.frame.origin.y, widthPerField, self.cardNumberTextField.frame.size.height)];
    self.expirationTextField.backgroundColor = [UIColor greenColor];
    self.expirationTextField.font = [self fontWithNewSize:self.defaultFont newSize:maximumFontForFields];
    self.expirationTextField.adjustsFontSizeToFitWidth = YES;
    self.expirationTextField.delegate = self;
    self.expirationTextField.hidden = YES;
    self.expirationTextField.inputAccessoryView = self.accessoryToolBar;
    self.expirationTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.expirationTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.expirationTextField addTarget:self action:@selector(expirationTextFieldValueChanged) forControlEvents:UIControlEventEditingChanged];
    
    [self addSubview:self.expirationTextField];
    
    
    self.cvcTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.expirationTextField.frame.origin.x + self.expirationTextField.frame.size.width + padding, self.cardNumberTextField.frame.origin.y, widthPerField, self.cardNumberTextField.frame.size.height)];
    self.cvcTextField.backgroundColor = [UIColor greenColor];
    self.cvcTextField.font = [self fontWithNewSize:self.defaultFont newSize:maximumFontForFields];
    self.cvcTextField.adjustsFontSizeToFitWidth = YES;
    self.cvcTextField.delegate = self;
    self.cvcTextField.hidden = YES;
    self.cvcTextField.inputAccessoryView = self.accessoryToolBar;
    self.cvcTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.cvcTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.cvcTextField addTarget:self action:@selector(cvcTextFieldValueChanged) forControlEvents:UIControlEventEditingChanged];
    
    [self addSubview:self.cvcTextField];
    
    self.zipTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.cvcTextField.frame.origin.x + self.cvcTextField.frame.size.width + padding, self.cardNumberTextField.frame.origin.y, widthPerField, self.cardNumberTextField.frame.size.height)];
    self.zipTextField.backgroundColor = [UIColor greenColor];
    self.zipTextField.adjustsFontSizeToFitWidth = YES;
    self.zipTextField.font = [self fontWithNewSize:self.defaultFont newSize:maximumFontForFields];
    self.zipTextField.delegate = self;
    self.zipTextField.hidden = YES;
    self.zipTextField.inputAccessoryView = self.accessoryToolBar;
    self.zipTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.zipTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self addSubview:self.zipTextField];

}

#pragma mark - Setters for updating placholders when client overrides defaults
- (void)setYearPlaceholder:(NSString *)yearPlaceholder {
    
    _yearPlaceholder = yearPlaceholder;
    [self updatePlaceholders];
}

- (void)setMonthPlaceholder:(NSString *)monthPlaceholder {
    _monthPlaceholder = monthPlaceholder;
    [self updatePlaceholders];
}

- (void)setMonthYearSeparator:(NSString *)monthYearSeparator {
    _monthYearSeparator = monthYearSeparator;
    [self updatePlaceholders];
}

- (void)setZipPlaceholder:(NSString *)zipPlaceholder {
    _zipPlaceholder = zipPlaceholder;
    [self updatePlaceholders];
}

- (void)setNumberPlaceholder:(NSString *)numberPlaceholder {
    _numberPlaceholder = numberPlaceholder;
    [self updatePlaceholders];
}

- (void)setCvcPlaceholder:(NSString *)cvcPlaceholder {
    _cvcPlaceholder = cvcPlaceholder;
    [self updatePlaceholders];
}

- (void)updatePlaceholders {
    self.expirationTextField.placeholder = [NSString stringWithFormat:@"%@%@%@", self.monthPlaceholder, self.monthYearSeparator, self.yearPlaceholder];
    self.cvcTextField.placeholder = self.cvcPlaceholder;
    self.zipTextField.placeholder = self.zipPlaceholder;
    self.cardNumberTextField.placeholder = self.numberPlaceholder;
}

- (void)setupBackSide {
    self.cardNumberTextField.hidden = YES;
    self.lastFourLabel.hidden = self.expirationTextField.hidden = self.cvcTextField.hidden = NO;
    if (self.includeZipCode)
        self.zipTextField.hidden = NO;
    
    self.lastFourLabel.text = self.lastFour;
}

- (void)setupFrontSide {
    self.lastFourLabel.hidden = self.expirationTextField.hidden = self.cvcTextField.hidden = self.zipTextField.hidden = YES;
    self.cardNumberTextField.hidden = NO;
}


- (IBAction)next:(id)sender {
    if (self.activeTextField == self.cardNumberTextField) {
        if (![self isValidCardNumber]){
            [self invalidFieldState];
            return;
        }
        [self setupBackSide];
        [self.expirationTextField becomeFirstResponder];
    } else if (self.activeTextField == self.expirationTextField) {
        [self.cvcTextField becomeFirstResponder];
    } else if (self.activeTextField == self.cvcTextField) {
        if (self.includeZipCode)
            [self.zipTextField becomeFirstResponder];
    }
}

- (IBAction)previous:(id)sender {
    if (self.activeTextField == self.expirationTextField) {
        [self setupFrontSide];
        [self.cardNumberTextField becomeFirstResponder];
    } else if (self.activeTextField == self.cvcTextField) {
        [self.expirationTextField becomeFirstResponder];
    } else if (self.activeTextField == self.zipTextField) {
        [self.cvcTextField becomeFirstResponder];
    }
}


- (void)setupAccessoryToolbar {
    UIBarButtonItem *previousButton = [[UIBarButtonItem alloc] initWithTitle:@"Previous" style:UIBarButtonItemStyleBordered target:self action:@selector(previous:)];
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(next:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    //UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTyping:)];
    self.accessoryToolBar.items = @[flexibleSpace, previousButton, nextButton];
}

- (UIFont *)fontWithNewSize:(UIFont *)font newSize:(CGFloat)pointSize {
    NSString *fontName = font.fontName;
    UIFont *newFont = [UIFont fontWithName:fontName size:pointSize];
    return newFont;
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.cardNumberTextField) {
        self.paymentStep = OKPaymentStepCCNumber;
        [self animateLeftView:self.cardType];
    } else if (textField == self.cvcTextField) {
        [self animateLeftView:OKCardTypeCvc];
        self.paymentStep = OKPaymentStepSecurityCode;
    } else if (textField == self.expirationTextField) {
        self.paymentStep = OKPaymentStepExpiration;
        [self animateLeftView:self.cardType];
    } else if (textField == self.zipTextField) {
        self.paymentStep = OKPaymentStepSecurityZip;
        [self animateLeftView:self.cardType];
    }
    
    if ([self.delegate respondsToSelector:@selector(didChangePaymentStep:)]) {
        [self.delegate didChangePaymentStep:self.paymentStep];
    }
    
    self.activeTextField = textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSLog(@"Text: %@, replacementString: %@, Length of text %d", textField.text, string, textField.text.length);
    if ([string isEqualToString:@" "])
        return NO;
    
    if (self.activeTextField == self.cardNumberTextField) {
        if (textField.text.length == 0) {
            if ([string isEqualToString:@"4"]) {
                [self animateLeftView:OKCardTypeVisa];
                _cardType = OKCardTypeVisa;
            } else if ([string isEqualToString:@"5"]) {
                [self animateLeftView:OKCArdTypeMastercard];
                _cardType = OKCArdTypeMastercard;
            } else {
                [self animateLeftView:OKCardTypeUnknown];
                _cardType = OKCardTypeUnknown;
            }
        }
        
        if ((textField.text.length == 4 || textField.text.length == 9 || textField.text.length == 14) && string.length != 0) {
            textField.text = [textField.text stringByAppendingFormat:@" %@", string];
            return NO;
        } else if (textField.text.length == 19 && ![string isEqualToString:@""]) {
            return NO;
        }
    } else if (self.activeTextField == self.expirationTextField) {
        if (textField.text.length == 5 && ![string isEqualToString:@""]) {
            return NO;
        }
        
        if ([string integerValue] > 1 && textField.text.length == 0 && ![string isEqualToString:@"0"]) {
            textField.text = [@"0" stringByAppendingFormat:@"%@/", string];
            return NO;
        }
        
        // If the first number is a one, the only valid
        if (textField.text.length == 1 && [string integerValue] > 2) {
            return NO;
        }
        
        if ([string isEqualToString:@"/"]) {
            if (textField.text.length == 1) {
                textField.text = [@"0" stringByAppendingFormat:@"%@/", textField.text];
                return NO;
            } else {
                
            }
        } else if (textField.text.length == 1 && ![string isEqualToString:@""]) {
            textField.text = [textField.text stringByAppendingFormat:@"%@/", string];
            return NO;
        }
    } else if (self.activeTextField == self.cvcTextField) {
        if (textField.text.length == 4 && ![string isEqualToString:@""]) {
            return NO;
        }

    }
    
    return YES;
}

- (void)expirationTextFieldValueChanged {
    if (self.ccNumberInvalid)
        [self resetFieldState];
    
    if (self.expirationTextField.text.length == 5) {
        NSArray *expirationParts = [self.expirationTextField.text componentsSeparatedByString:self.monthYearSeparator];
        _cardMonth = expirationParts[0];
        _cardYear = expirationParts[1];
        if ([self isValidExpiration]) {
            [self next:self];
        }
    }

}

- (void)cvcTextFieldValueChanged {
    if (self.cvcTextField.text.length > 2) {
        _cardCvc = self.cvcTextField.text;
        if (self.includeZipCode) {
            [self next:self];

        } else {
            
        }
    }
}

- (void)zipTextFieldValueChanged {
    
}

- (void)cardNumberTextFieldValueChanged {
    if (self.ccNumberInvalid) 
        [self resetFieldState];
    
    self.trimmedNumber = [self.cardNumberTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];

    
    if (self.cardType == OKCArdTypeMastercard) {
        if (self.trimmedNumber.length == 16 && [self isValidCardNumber]) {
            [self next:self];
        }
    } else if (self.cardType == OKCardTypeVisa) {
        if ((self.trimmedNumber.length > 12 && self.trimmedNumber.length < 20) && [self isValidCardNumber]) {
            [self next:self];
        }
    } else if ([self isValidCardNumber]){
        [self next:self];
    }
    
}

#pragma mark - Validation methods
- (BOOL)isFormValid {
    if ([self isValidExpiration] && [self isValidCardNumber]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isValidCardNumber {
    if (self.cardType == OKCardTypeUnknown) {
        NSLog(@"Invalid card type");
        [self invalidFieldState];
        return NO;
    } else if ( self.cardType == OKCardTypeVisa) {
        if (self.trimmedNumber.length == 16 && ![CreditCardValidation validateCard:self.trimmedNumber]) {
            [self invalidFieldState];
            return NO;
        } else if (![CreditCardValidation validateCard:self.trimmedNumber]) {
            return NO;
        }
    } else if (self.cardType == OKCArdTypeMastercard) {
        if (![CreditCardValidation validateCard:self.trimmedNumber]) {
            [self invalidFieldState];
            return NO;
        }
    }
    
    _cardNumber = self.trimmedNumber;
    self.lastFour = [self.cardNumber substringFromIndex: [self.cardNumber length] - 4];
    return YES;
}

- (BOOL)isValidExpiration {

    if ([self.cardMonth integerValue] < 13 && [self.cardMonth integerValue] > 0 && [self.cardYear integerValue] >= self.minYear && [self.cardYear integerValue] <= self.maxYear) {
        return YES;
    }
    [self invalidFieldState];
    return NO;
}
    


#pragma mark - Animation methods

- (void)animateLeftView:(OKCardType)cardType {
    if (self.displayingCardType != cardType) {
        self.displayingCardType = cardType;
        [UIView transitionWithView:self.leftCardView duration:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft  animations:^{
            self.leftCardView.image = [self imageForCardType:cardType];
        } completion:^(BOOL finished) {
            //self.leftView = visaView;
        }];
    }
}

- (UIImage *)imageForCardType:(OKCardType)cardType {
    UIImage *image;
    switch (cardType) {
        case OKCardTypeVisa:
            image = [UIImage imageNamed:@"visa_icon"];
            break;
        case OKCArdTypeMastercard:
            image = [UIImage imageNamed:@"mastercard_icon"];
            break;
        case OKCardTypeUnknown:
            image = [UIImage imageNamed:@"credit_card_icon"];
            break;
        case OKCardTypeCvc:
            image = [UIImage imageNamed:@"cvc_icon"];
            break;
        default:
            break;
    }
    return image;
}


- (void)shakeAnimation:(UIView *) view {
    const int reset = 5;
    const int maxShakes = 6;
    
    //pass these as variables instead of statics or class variables if shaking two controls simultaneously
    static int shakes = 0;
    static int translate = reset;
    
    [UIView animateWithDuration:0.09-(shakes*.01) // reduce duration every shake from .09 to .04
                          delay:0.01f//edge wait delay
                        options:(enum UIViewAnimationOptions) UIViewAnimationCurveEaseInOut
                     animations:^{view.transform = CGAffineTransformMakeTranslation(translate, 0);}
                     completion:^(BOOL finished){
                         if(shakes < maxShakes){
                             shakes++;
                             
                             //throttle down movement
                             if (translate>0)
                                 translate--;
                             
                             //change direction
                             translate*=-1;
                             [self shakeAnimation:view];
                         } else {
                             view.transform = CGAffineTransformIdentity;
                             shakes = 0;//ready for next time
                             translate = reset;//ready for next time
                             return;
                         }
                     }];
}

#pragma mark - Field styles
- (void)invalidFieldState {
    self.containerView.image = [[UIImage imageNamed:@"field_cell_error"] resizableImageWithCapInsets:(UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0))];
    self.ccNumberInvalid = YES;
    [self shakeAnimation:self.activeTextField.textInputView];
    self.activeTextField.textColor = [UIColor redColor];
}

- (void)resetFieldState {
    self.containerView.image = [[UIImage imageNamed:@"field_cell"] resizableImageWithCapInsets:(UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0))];
    self.activeTextField.textColor = self.defaultFontColor;
    self.ccNumberInvalid = NO;
}


@end
