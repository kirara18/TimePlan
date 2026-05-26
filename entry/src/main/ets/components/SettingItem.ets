import { AppColors } from '../utils/AppColors'
@Component
export struct SettingItem {
  @Prop title: string = ''
  @Prop value: string = ''

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor(AppColors.GRAY_900)

      Blank()

      Text(this.value)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)

      Text(' >')
        .fontSize(14)
        .fontColor(AppColors.GRAY_400)
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(14)
    .margin({ bottom: 10 })
  }
}
