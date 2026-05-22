import { AppColors } from '../utils/AppColors'

@Component
export struct PrivacyPolicyPage {
  @Prop themeColor: string = AppColors.BLUE
  onBack: () => void = () => {}

  build() {
    Scroll() {
      Column() {
        this.Header('隐私政策')

        this.Section(
          '一、适用范围',
          '本隐私政策适用于“鸿蒙全时计划 App”的日历安排、计划管理、专注模式、统计分析、主题设置等功能。当前版本主要面向个人时间管理场景，帮助用户在本地记录待办、便签、习惯打卡和专注记录。'
        )

        this.Section(
          '二、我们处理的数据',
          '应用会在本机保存用户主动创建的计划、便签、习惯打卡、专注记录、主题偏好等数据。这些数据用于在日历页展示安排、在统计页生成个人完成情况，以及在下次打开应用时恢复用户记录。'
        )

        this.Section(
          '三、数据存储方式',
          '当前版本使用 HarmonyOS Preferences 本地持久化能力保存数据。数据默认保存在用户设备本地，不会自动上传至云端，也不会主动共享给第三方。'
        )

        this.Section(
          '四、权限使用说明',
          '当前版本不需要访问通讯录、相机、麦克风、相册、定位等敏感权限。如后续版本新增图片便签、系统通知或跨设备同步等能力，我们会在使用前说明用途，并按系统要求申请授权。'
        )

        this.Section(
          '五、数据删除',
          '用户可以在“我的”页使用“清空全部本地数据”功能删除本机保存的计划、便签、习惯打卡和专注记录。删除后数据将无法在当前应用内恢复，请谨慎操作。'
        )

        this.Section(
          '六、未成年人保护',
          '本应用为通用效率工具，不包含社交、交易、游戏抽奖等内容。未成年人使用时，建议在监护人指导下合理记录学习计划与生活安排。'
        )

        this.Section(
          '七、政策更新',
          '如果后续版本增加云同步、账号登录、通知提醒、数据导出等能力，隐私政策会同步更新，并在应用内提供查看入口。'
        )

        Text('更新日期：2026-05-22')
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
