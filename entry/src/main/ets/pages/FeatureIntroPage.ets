import { AppColors } from '../utils/AppColors'

@Component
export struct FeatureIntroPage {
  @Prop themeColor: string = AppColors.BLUE
  @Prop title: string = ''
  @Prop description: string = ''
  onBack: () => void = () => {}

  build() {
    Scroll() {
      Column() {
        this.Header(this.title)

        Column() {
          Text(this.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          Text(this.description)
            .fontSize(16)
            .fontColor(AppColors.GRAY_500)
            .lineHeight(26)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BG)
  }

  @Builder
  Header(title: string) {
    Row() {
      Button('返回')
        .width(72)
        .height(36)
        .fontSize(14)
        .backgroundColor(this.themeColor)
        .borderRadius(12)
        .onClick(() => {
          this.onBack()
        })

      Blank()

      Text(title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)

      Blank()

      Text('')
        .width(72)
    }
    .width('100%')
    .margin({ top: 30, bottom: 18 })
  }
}
