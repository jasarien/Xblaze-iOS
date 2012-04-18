//
//  IFTextCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFTextCellController.h"

#import	"IFControlTableViewCell.h"

@implementation IFTextCellController

@synthesize updateTarget, updateAction, textField, shouldResignFirstResponderOnReturn;
@synthesize keyboardType, autocapitalizationType, autocorrectionType, secureTextEntry, indentationLevel;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel andPlaceholder:(NSString *)newPlaceholder atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		placeholder = [newPlaceholder retain];
		key = [newKey retain];
		model = [newModel retain];

		keyboardType = UIKeyboardTypeAlphabet;
		autocapitalizationType = UITextAutocapitalizationTypeNone;
		autocorrectionType = UITextAutocorrectionTypeNo;
		secureTextEntry = NO;
		indentationLevel = 0;
		
		// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
		// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
		// and cross our fingers that this doesn't screw things up in the future.
		
		CGFloat viewWidth;
		if (! label || [label length] == 0)
		{
			// there is no label, so use the entire width of the cell
			
			viewWidth = 280.0f - (20.0f * indentationLevel);
		}
		else
		{
			// use about half of the cell (this matches the metrics in the Settings app)
			
			viewWidth = 150.0f;
		}
		
		// add a text field to the cell
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 21.0f);
		self.textField = [[[UITextField alloc] initWithFrame:frame] autorelease];
		[self.textField addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventEditingChanged];
		[self.textField setDelegate:self];
		NSString *value = [model objectForKey:key];
		[self.textField setText:value];
		[self.textField setFont:[UIFont systemFontOfSize:17.0f]];
		[self.textField setBorderStyle:UITextBorderStyleNone];
		[self.textField setPlaceholder:placeholder];
		[self.textField setReturnKeyType:UIReturnKeyDone];
		[self.textField setKeyboardType:keyboardType];
		[self.textField setAutocapitalizationType:autocapitalizationType];
		[self.textField setAutocorrectionType:autocorrectionType];
		[self.textField setBackgroundColor:[UIColor whiteColor]];
		[self.textField setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[placeholder release];
	[key release];
	[model release];
	
	[super dealloc];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"TextDataCell";
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;
	
	[self.textField setSecureTextEntry:secureTextEntry];
	cell.view = self.textField;
	
    return cell;
}

- (void)updateValue:(id)sender
{
	// update the model with the text change
	[model setObject:[sender text] forKey:key];
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)_textField
{
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)_textField
{	
	[self updateValue:self.textField];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)_textField
{
	if (shouldResignFirstResponderOnReturn)
	{
		// hide the keyboard
		[_textField resignFirstResponder];
	}
	
	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		// action is peformed after keyboard has had a chance to resign
		[updateTarget performSelector:updateAction withObject:_textField];
	}	
	
	return YES;
}

@end
