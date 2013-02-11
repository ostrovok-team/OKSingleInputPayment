/*
* Copyright (c) 2013 Ostrovok.ru
*
* Permission is hereby granted, free of charge, to any person 
* obtaining a copy of this software and associated documentation 
* files (the "Software"), to deal in the Software without restriction, 
* including without limitation the rights to use, copy, modify, merge, 
* publish, distribute, sublicense, and/or sell copies of the Software,
* and to permit persons to whom the Software is furnished to do so, 
* subject to the following conditions:

* The above copyright notice and this permission notice shall be included 
* in all copies or substantial portions of the Software.

* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
* OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <UIKit/UIKit.h>

typedef enum {
    OKPaymentStepCCNumber,
    OKPaymentStepExpiration,
    OKPaymentStepSecurityCode,
    OKPaymentStepSecurityZip
} OKPaymentStep;

typedef enum {
    OKCardTypeVisa,
    OKCArdTypeMastercard,
    OKCardTypeUnknown,
    OKCardTypeCvc
} OKCardType;

@protocol OKSingleInputPaymentDelegate;

@interface OKSingleInputPayment : UIView <UITextFieldDelegate>
@property (strong, nonatomic) UIFont *defaultFont;
@property (strong, nonatomic) UIColor *defaultFontColor;
@property (strong, readonly) NSString *cardNumber;
@property (strong, readonly) NSString *cardCvc;
@property (strong, readonly) NSString *cardMonth;
@property (strong, readonly) NSString *cardYear;
@property (strong, readonly) NSString *cardZip;

@property (readonly) OKCardType cardType;
/**
  Optionally include the zipcode field. This is an optional field as not all locales support this field..
 */
@property BOOL includeZipCode;
/**
 Optionally use an inputaccessory view with previous<->next
 */
@property BOOL useInputAccessory;

@property (strong, nonatomic) NSString *cvcPlaceholder;
@property (strong, nonatomic) NSString *zipPlaceholder;
@property (strong, nonatomic) NSString *numberPlaceholder;
@property (strong, nonatomic) NSString *monthYearSeparator;
@property (strong, nonatomic) NSString *monthPlaceholder;
@property (strong, nonatomic) NSString *yearPlaceholder;

@property (strong, nonatomic) UIFont *placeholderFont;

@property (weak, nonatomic) id <OKSingleInputPaymentDelegate> delegate;


@end


@protocol OKSingleInputPaymentDelegate <NSObject>

@optional
- (void)paymentDetailsValid;
- (void)didChangePaymentStep:(OKPaymentStep)paymentStep;

@end