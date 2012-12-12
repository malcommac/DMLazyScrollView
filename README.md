DMLazyScrollView : Lazy Loading UIScrollView (with infinite page scrolling)
================

DMLazyScrollView for iOS (with support for infinite scrolling) allows you to create and endless (in both horizontal and vertical direction) UIScrollView organized in pages and load UIViews dynamically only when needed by reducing time and memory consumption.

When you have lots of UIViews to show inside a scroll view you don't want to waste memory and time by creating a big UIScrollView content view, load all subviews at the same time and show them; it does not make sense and it's slow on older devices.

DMLazyScrollView allows you to load lazily UIViews and animate page scrolling easily. You can use it to load images or entire views without pain.

![DMLazyScrollView Example Project](http://i.imgur.com/lhmdn.png)


## Donations

If you found this project useful, please donate.
There’s no expected amount and I don’t require you to.
[MAKE YOUR DONATION](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=GS3DBQ69ZBKWJ)

## License (MIT)

Copyright (c) 2012 Daniele Margutti

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
