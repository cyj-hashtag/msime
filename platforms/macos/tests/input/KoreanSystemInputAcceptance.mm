#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#include <cstdio>
#include <cstring>
#include <unistd.h>

// 这个入口只用系统事件和原生编辑框，不导入控制器，也不直接调用宿主库。
// 必须在已安装本次构建、已手动选择相应韩语布局的 Mac 登录会话中执行。
static void Pump(NSTimeInterval seconds) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while (end.timeIntervalSinceNow > 0) {
        NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
            untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01] inMode:NSDefaultRunLoopMode dequeue:YES];
        if (event) [NSApp sendEvent:event];
    }
}

static NSString *SelectedSource() {
    TISInputSourceRef source = TISCopyCurrentKeyboardInputSource();
    if (!source) return @"";
    NSString *identifier = [(__bridge NSString *)(CFStringRef)TISGetInputSourceProperty(source, kTISPropertyInputSourceID) copy];
    CFRelease(source);
    return identifier ?: @"";
}

static void Key(CGKeyCode code, CGEventFlags flags = 0) {
    for (NSNumber *down in @[@YES, @NO]) {
        CGEventRef event = CGEventCreateKeyboardEvent(nullptr, code, down.boolValue);
        if (!event) [NSException raise:@"AcceptanceFailure" format:@"无法建立键盘事件"];
        CGEventSetFlags(event, flags);
        CGEventPostToPid(getpid(), event);
        CFRelease(event);
        Pump(0.08);
    }
}

static void Type(NSString *text) {
    NSDictionary *codes = @{@"a":@0, @"b":@11, @"d":@2, @"g":@5, @"h":@4, @"k":@40,
        @"n":@45, @"q":@12, @"r":@15, @"s":@1, @"u":@32, @"v":@9, @"w":@13, @"x":@7, @"z":@6};
    for (NSUInteger i = 0; i < text.length; ++i) {
        NSString *letter = [text substringWithRange:NSMakeRange(i, 1)];
        NSNumber *code = codes[letter.lowercaseString];
        if (!code) [NSException raise:@"AcceptanceFailure" format:@"未知测试按键 %@", letter];
        Key(code.unsignedShortValue, [letter isEqual:letter.uppercaseString] ? kCGEventFlagMaskShift : 0);
    }
}

static void Expect(NSMutableArray *results, NSTextView *view, NSString *text, BOOL marked, NSString *name) {
    Pump(0.15);
    NSDictionary *result = @{@"case":name, @"expected":text, @"actual":view.string,
        @"marked":@(view.hasMarkedText), @"expected_marked":@(marked), @"input_source":SelectedSource(),
        @"passed":@([view.string isEqual:text] && view.hasMarkedText == marked)};
    [results addObject:result];
    if (![result[@"passed"] boolValue]) [NSException raise:@"AcceptanceFailure" format:@"%@：%@", name, result];
}

static void Clear(NSTextView *view) {
    if (view.hasMarkedText) [NSException raise:@"AcceptanceFailure" format:@"清理前组字尚未结束"];
    view.string = @"";
    [view setSelectedRange:NSMakeRange(0, 0)];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 2 && strcmp(argv[1], "--probe") == 0) {
            NSDictionary *probe = @{@"system_input_executed":@NO,
                @"event_posting_allowed":@(CGPreflightPostEventAccess()), @"input_source":SelectedSource()};
            NSData *data = [NSJSONSerialization dataWithJSONObject:probe options:NSJSONWritingPrettyPrinted error:nil];
            puts([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);
            return 0;
        }
        if (argc != 4 || (strcmp(argv[1], "romaja") != 0 && strcmp(argv[1], "dubeolsik") != 0)) {
            fputs("用法：korean-system-input-acceptance <romaja|dubeolsik> <已安装输入法.app绝对路径> <报告.json绝对路径>\n", stderr);
            return 2;
        }
        NSString *layout = @(argv[1]), *bundlePath = @(argv[2]), *output = @(argv[3]);
        if (!bundlePath.isAbsolutePath || !output.isAbsolutePath) return 2;
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *sourceID = [bundle.bundleIdentifier stringByAppendingString:@".Korean"];
        NSMutableArray *results = [NSMutableArray array];
        NSMutableDictionary *report = [@{@"layout":layout, @"bundle_path":bundlePath, @"cases":results,
            @"system_input_executed":@NO, @"passed":@NO} mutableCopy];
        TISInputSourceRef previous = nullptr;
        NSWindow *window = nil;
        int status = 1;
        @try {
            if (!CGPreflightPostEventAccess())
                [NSException raise:@"AcceptancePrerequisite" format:@"当前进程没有系统按键投递权限；未请求或修改权限，未执行验收"];
            NSURL *registered = bundle.bundleIdentifier
                ? [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundle.bundleIdentifier] : nil;
            if (!registered || ![registered.URLByResolvingSymlinksInPath.path isEqual:[bundle.bundleURL URLByResolvingSymlinksInPath].path])
                [NSException raise:@"AcceptancePrerequisite" format:@"LaunchServices 登记的输入法与指定构建不一致"];
            NSDictionary *filter = @{(__bridge NSString *)kTISPropertyInputSourceID:sourceID};
            CFArrayRef sources = TISCreateInputSourceList((__bridge CFDictionaryRef)filter, false);
            if (!sources || CFArrayGetCount(sources) != 1) {
                if (sources) CFRelease(sources);
                [NSException raise:@"AcceptancePrerequisite" format:@"本次构建的韩语输入源尚未安装或启用"];
            }
            previous = TISCopyCurrentKeyboardInputSource();
            OSStatus selected = TISSelectInputSource((TISInputSourceRef)CFArrayGetValueAtIndex(sources, 0));
            if (selected != noErr) {
                CFRelease(sources);
                [NSException raise:@"AcceptancePrerequisite" format:@"选择输入源失败：%d", (int)selected];
            }
            [NSApplication sharedApplication];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            [NSApp finishLaunching];
            window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 700, 400)
                styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
            window.releasedWhenClosed = NO;
            window.title = @"水杉韩语系统输入验收";
            NSTextView *first = [[NSTextView alloc] initWithFrame:NSMakeRect(10, 210, 680, 180)];
            NSTextView *second = [[NSTextView alloc] initWithFrame:NSMakeRect(10, 10, 680, 180)];
            [window.contentView addSubview:first];
            [window.contentView addSubview:second];
            [window makeKeyAndOrderFront:nil];
            [NSApp activateIgnoringOtherApps:YES];
            [window makeFirstResponder:first];
            Pump(1);
            selected = TISSelectInputSource((TISInputSourceRef)CFArrayGetValueAtIndex(sources, 0));
            CFRelease(sources);
            Pump(0.5);
            if (selected != noErr || ![SelectedSource() isEqual:sourceID])
                [NSException raise:@"AcceptancePrerequisite" format:@"窗口激活后系统恢复了其他输入源；请先在此窗口选择水杉韩语"];
            report[@"system_input_executed"] = @YES;
            BOOL romaja = [layout isEqual:@"romaja"];
            Type(romaja ? @"hang" : @"gks");
            Expect(results, first, romaja ? @"항" : @"한", YES, @"预编辑");
            Type(romaja ? @"ug" : @"rnr");
            Expect(results, first, @"한국", YES, @"后续组字不重复前缀");
            Key(36);
            Expect(results, first, @"한국\n", NO, @"Return 提交并交给应用换行");
            Clear(first);
            if (romaja) {
                Type(@"bang"); Key(51);
                Expect(results, first, @"반", YES, @"按原始拼写退格");
                Key(53); Expect(results, first, @"", NO, @"Escape 取消");
                Type(@"gwa"); Key(51);
                Expect(results, first, @"구", YES, @"复合元音退格"); Key(53);
                Type(@"xa"); Expect(results, first, @"아", YES, @"x 声母"); Key(53);
                Type(@"Ga"); Key(43);
                Expect(results, first, @"까,", NO, @"紧音和半角标点"); Clear(first);
                Type(@"hanqvz");
                Expect(results, first, @"한qvz", NO, @"布局外字母保留"); Clear(first);
            }
            Type(romaja ? @"han" : @"gks"); Key(36, kCGEventFlagMaskAlternate); Key(18);
            Expect(results, first, @"韓", NO, @"系统候选窗口选择汉字"); Clear(first);
            Type(romaja ? @"han" : @"gks");
            [window makeFirstResponder:second]; Pump(0.5);
            Expect(results, first, @"한", NO, @"失焦文字留在原输入框");
            Type(romaja ? @"hangug" : @"gksrnr");
            Expect(results, second, @"한국", YES, @"新输入框独立组字"); Key(36);
            Expect(results, second, @"한국\n", NO, @"新输入框提交");
            Expect(results, first, @"한", NO, @"原输入框不被改写");
            report[@"passed"] = @YES;
            status = 0;
        } @catch (NSException *exception) {
            report[@"error"] = exception.reason ?: exception.name;
            if ([exception.name isEqual:@"AcceptancePrerequisite"]) status = 77;
        } @finally {
            [window close];
            if (previous) { TISSelectInputSource(previous); CFRelease(previous); }
            NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
            if (![data writeToFile:output atomically:YES]) status = 2;
            puts([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);
        }
        return status;
    }
}
