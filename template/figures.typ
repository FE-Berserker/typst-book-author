// 插图尺寸助手
//
// 为什么要这个文件：给插图定尺寸时，两种常见写法各有一个坑。
//
// - 只写 width（例如 width: 55%）：横图没问题；竖图会按比例把高度一起推高，
//   超过版心时被页面裁掉——PDF 里图还有，纸上看不见。
// - 只写 height（例如 height: 88%）：竖图没问题；横图会按比例把宽度推得比
//   版心还宽，超出右边距。
//
// auto-image 先量出图片的自然宽高比，再二选一：横图撑满版心宽，竖图按高度
// 上限收——两种越界都不会发生，也不会为了留位置而凭空空出一块。

/// 自适应插图：横图撑满版心宽，竖图收到高度上限以内。
///
/// - path: 图片路径，**按项目根（本文件所在目录）解析**，不是按调用它的章文件
/// - max-height: 竖图最多占版心高度的比例，默认 0.88（剩下的留给图注）
///
/// 例：
/// ```
/// #figure(auto-image("images/chart.png"), caption: [采样曲线])
/// ```
/// 章文件要自己 `#import "../figures.typ": auto-image`——include 不继承作用域。
/// 要固定尺寸就直接写 `image(...)`，不要用这个函数。
#let auto-image(path, max-height: 0.88) = layout(size => {
  let natural = measure(image(path))
  let height-at-full-width = size.width * (natural.height / natural.width)
  if height-at-full-width <= size.height * max-height {
    image(path, width: 100%)
  } else {
    image(path, height: size.height * max-height)
  }
})
