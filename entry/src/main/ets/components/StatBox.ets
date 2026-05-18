@Component
export struct StatBox {
  @Prop themeColor: string = '#4F7CFF'
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
        .fontColor('#6B7280')
        .margin({ top: 4 })
    }
    .width('30%')
    .height(72)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F3F6FF')
    .borderRadius(14)
  }
}
