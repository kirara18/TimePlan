import { AppColors } from '../utils/AppColors'

@Component
export struct AboutAppPage {
  @Prop themeColor: string = AppColors.BLUE
  onBack: () => void = () => {}

  build() {
    Scroll() {
      Column() {
        this.Header('关于应用')

        Column() {
          Text('鸿蒙全时计划 App')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 8 })

          Text('TimePlan')
            .fontSize(15)
            .fontColor(this.themeColor)
            .margin({ bottom: 12 })

          Text('版本：V1.1.1')
            .fontSize(14)
            .fontColor(AppColors.GRAY_500)

          Text('定位：个人时间管理与学习计划工具')
            .fontSize(14)
            .fontColor(AppColors.GRAY_500)
            .margin({ top: 6 })
        }
        .width('100%')
        .padding(22)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(20)
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        this.Section(
          '核心功能',
          '应用包含日历安排、计划管理、专注模式、统计分析和个人设置等模块。日历页按月展示安排，计划页管理待办，专注页记录学习专注时长，统计页展示完成情况。'
        )

        this.Section(
          '产品特色',
          '当前版本重点体现模块联动、本地存储、主题切换和日历汇总。用户在计划、专注等模块产生的数据可在日历和统计页中统一查看。'
        )

        this.Section(
          '数据说明',
          '当前版本数据主要保存在本地设备中，用户可在“我的”页清空本地数据。隐私政策和用户协议可在“我的”页查看。'
        )

        this.Section(
          '开发说明',
          '本应用基于 HarmonyOS / ArkTS / DevEco Studio 开发，适用于鸿蒙移动应用课程项目和后续上架完善。'
        )

        Text('© 2026 TimePlan')
          .fontSize(13)
          .fontColor(AppColors.GRAY_400)
          .margin({ top: 10, bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.GRAY_BLUE_50)
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
    .backgroundColor(AppColors.WHITE)
    .borderRadius(18)
    .margin({ bottom: 14 })
    .alignItems(HorizontalAlign.Start)
  }
}
