@Component
export struct SettingItem {
  @Prop title: string = ''
  @Prop value: string = ''

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor('#111827')

      Blank()

      Text(this.value)
        .fontSize(14)
        .fontColor('#6B7280')

      Text(' >')
        .fontSize(14)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ bottom: 10 })
  }
}
