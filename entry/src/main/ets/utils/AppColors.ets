export class AppColors {
  static readonly BLUE: string = '#4F7CFF'
  static readonly GREEN: string = '#22C55E'
  static readonly RED: string = '#EF4444'

  // 纯白色只用于蓝色/红色/绿色按钮上的文字，不用于普通卡片背景。
  static readonly WHITE: string = '#FFFFFF'

  // 语义背景色：通过 base/dark 资源自动适配系统深浅色模式。
  static readonly PAGE_BG: ResourceColor = $r('app.color.page_bg')
  static readonly CARD_BG: ResourceColor = $r('app.color.card_bg')
  static readonly SURFACE_BG: ResourceColor = $r('app.color.surface_bg')
  static readonly SURFACE_ALT_BG: ResourceColor = $r('app.color.surface_alt_bg')
  static readonly BORDER_BG: ResourceColor = $r('app.color.border_bg')

  // 兼容原有命名，同时改为可随系统深浅色变化的资源色。
  static readonly GRAY_BLUE_50: ResourceColor = $r('app.color.page_bg')
  static readonly GRAY_50: ResourceColor = $r('app.color.surface_bg')
  static readonly GRAY_100: ResourceColor = $r('app.color.surface_alt_bg')
  static readonly GRAY_200: ResourceColor = $r('app.color.border_bg')
  static readonly GRAY_400: ResourceColor = $r('app.color.text_tertiary')
  static readonly GRAY_500: ResourceColor = $r('app.color.text_secondary')
  static readonly GRAY_800: ResourceColor = $r('app.color.text_heading')
  static readonly GRAY_900: ResourceColor = $r('app.color.text_primary')

  static readonly BLUE_50: ResourceColor = $r('app.color.blue_50')
  static readonly INDIGO_50: ResourceColor = $r('app.color.indigo_50')
  static readonly GREEN_50: ResourceColor = $r('app.color.green_50')
  static readonly GREEN_100: ResourceColor = $r('app.color.green_100')
  static readonly RED_100: ResourceColor = $r('app.color.red_100')

  static readonly INPUT_BG: ResourceColor = $r('app.color.input_bg')
  static readonly INPUT_TEXT: ResourceColor = $r('app.color.input_text')
  static readonly INPUT_PLACEHOLDER: ResourceColor = $r('app.color.input_placeholder')
}
