import { AppColors } from '../utils/AppColors'

@Component
export struct EmptyState {
  @Prop themeColor: string = AppColors.BLUE
  @Prop iconText: string = '◎'
  @Prop title: string = '暂无数据'
  @Prop description: string = '当前还没有可展示的内容'

  build() {
    Column() {
      Text(this.iconText)
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor)
        .margin({ bottom: 8 })

      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
        .margin({ bottom: 6 })

      Text(this.description)
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
    }
    .width('100%')
    .padding({ top: 22, bottom: 22, left: 18, right: 18 })
    .backgroundColor(AppColors.SURFACE_BG)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
  }
}
