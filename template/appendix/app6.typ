#import "@preview/bookly:5.1.1": *
#import "../figstyle.typ": *
#import "@preview/plotsy-3d:0.2.1": plot-3d-surface
#import "@preview/maquette:0.1.3": render-stl
#import "@preview/vmesh:0.1.0": draw-mesh

= 三维与网格绘图

Typst 的三维绘图分两条路：一条是*用代码画*（CeTZ 的三维坐标系、plotsy-3d 的曲面），另一条是*把已有的三维数据渲染进来*（maquette 直接渲染 STL/OBJ/PLY，vmesh 读 Gmsh 有限元网格）。工程上更常用后者——模型与网格由 CAD 或前处理软件生成，Typst 只负责按统一风格出图。

*用代码画曲面*：图 @fig:surface 是 $z = x y$ 的双曲抛物面（索膜结构中常见的曲面形式），由 plotsy-3d 直接按函数绘制，坐标轴、刻度与配色都是它的默认输出。

#figure(
  {
    set text(size: 9pt)
    plot-3d-surface(
      (x, y) => x * y,
      subdivisions: 2,
      subdivision-mode: "decrease",
      scale-dim: (0.3 * 0.11, 0.3 * 0.11, 0.15 * 0.11 / 4),
      xdomain: (-8, 8),
      ydomain: (-8, 8),
      pad-low: (0, 0, 10),
      axis-step: (2, 2, 30),
    )
  },
  caption: [双曲抛物面 $z = x y$（plotsy-3d 绘制；这类曲面在索膜结构中常见）],
) <fig:surface>

*渲染网格*：图 @fig:mesh 是一段两层土地基剖面的有限元网格，网格文件（Gmsh 的 `.msh2` 文本格式）由前处理软件或脚本生成，vmesh 负责按物理域分色、按统一线宽出图。

#figure(
  {
    set text(font: fig-font, size: fig-size)
    draw-mesh(
      read("../data/soil-mesh.msh2"),
      width: 8cm,
      fill-elements: true,
      mesh-stroke: 0.25pt + rgb("#8a7f6a"),
      color-map: ("1": rgb("#cdb894"), "2": rgb("#eadfc6")),
    )
  },
  caption: [两层土地基剖面的有限元网格（vmesh 读取 Gmsh 文件，按物理域分色）],
) <fig:mesh>

*渲染实体模型*：图 @fig:stl 的工字钢是直接用 maquette 渲染 STL 文件得到的——相机、光照与材质都写在源码里，改一处参数重新编译即可，不必回 CAD 重新截图。

#figure(
  {
    set text(font: fig-font, size: fig-size)
    render-stl(
      read("../data/ibeam.stl", encoding: none),
      width: 5.5cm,
      background: none,
      antialias: 4,
      azimuth: 50,
    )
  },
  caption: [工字钢模型（maquette 直接渲染 STL 文件）],
) <fig:stl>

其余可用工具见表 @tab:3d-tools。

#figure(
  table(
    columns: (auto, auto, 1fr),
    table.header([工具], [方向], [能画什么]),
    [plotsy-3d 0.2.1],
    [数学 / 工程],
    [三维曲面 $z = f(x,y)$、参数曲线与曲面、向量场，基于 CeTZ 手绘],

    [maquette 0.1.3],
    [CAD 模型],
    [把 STL / OBJ / PLY 模型渲染成图片，相机、光照、材质都在源码里调],

    [vmesh 0.1.0],
    [有限元],
    [读 Gmsh 网格文件（2D/3D），按物理域分色，可开节点/单元编号，支持视角与光照],

    [larnt 0.1.0],
    [线稿],
    [三维线稿渲染：球、立方、圆柱、圆锥与 CSG 布尔运算，输出 SVG],

    [meshpad 0.1.0], [网格纸], [方格纸背景，适合手绘草图的底纹],
  ),
  caption: [三维与网格绘图常用工具],
) <tab:3d-tools>

#warning-box[两处限制：plotsy-3d 的坐标轴刻度只能取整数，z 值非整数时会直接报错（可选择整数取值的目标函数，或改用 maquette 渲染外部模型）；maquette 的相机参数以模型包围盒为基准，视角需要试几次才能调好。]
