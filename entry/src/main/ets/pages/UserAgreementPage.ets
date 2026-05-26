import { AppColors } from '../utils/AppColors'

@Component
export struct UserAgreementPage {
  @Prop themeColor: string = AppColors.BLUE
  onBack: () => void = () => {}

  build() {
    Scroll() {
      Column() {
        this.Header('用户协议')

        this.Section(
          '一、服务说明',
          '“鸿蒙全时计划 App”是一款个人效率管理应用，提供日历安排、计划管理、专注记录、统计分析、主题设置等功能。用户可使用本应用记录学习、工作和生活安排。'
        )

        this.Section(
          '二、用户责任',
          '用户应自行保证所记录内容的合法性、真实性和适当性，不得利用本应用记录、传播违法违规内容。本应用主要提供本地记录和管理能力，不对用户自行输入内容承担审核责任。'
        )

        this.Section(
          '三、数据与备份',
          '当前版本数据主要保存在本机。用户在卸载应用、清空数据或更换设备前，应自行确认是否需要备份重要内容。因用户主动删除、设备异常或系统清理导致的数据丢失，应用无法保证恢复。'
        )

        this.Section(
          '四、功能变化',
          '后续版本可能根据课程项目完善、用户反馈或上架要求调整页面、功能和文案。若涉及重要能力变化，会在应用内或版本说明中进行提示。'
        )

        this.Section(
          '五、免责声明',
          '本应用提供的是个人计划和记录辅助功能，不构成医疗、金融、法律、心理等专业建议。用户应结合自身情况合理安排计划和目标。'
        )

        this.Section(
          '六、协议更新',
          '我们可能根据功能变化和合规要求更新本协议。继续使用应用即表示用户了解并接受更新后的协议内容。'
        )

        Text('更新日期：2026-05-23')
          .fontSize(13)
          .fontColor(AppColors.GRAY_400)
          .margin({ top: 10, bottom: 30 })
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

  @Builder
  Section(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
        .margin({ bottom: 8 })

      Text(content)
        .fontSize(15)
        .fontColor(AppColors.GRAY_500)
        .lineHeight(24)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(18)
    .margin({ bottom: 14 })
    .alignItems(HorizontalAlign.Start)
  }
}
