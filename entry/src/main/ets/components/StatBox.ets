import { AppColors } from '../utils/AppColors'
@Component
export struct StatBox {
  @Prop themeColor: string = AppColors.BLUE
  @Prop title: string = ''
  @Prop value: string = ''

  build() {
    Column() {
      Text(this.value)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor)

      Text(this.title)
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .margin({ top: 4 })
    }
    .width('30%')
    .height(72)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.BLUE_50)
    .borderRadius(14)
  }
}
