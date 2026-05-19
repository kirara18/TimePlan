import {
  getToday,
  getYearFromDate,
  getMonthFromDate,
  getWeekTitles,
  buildMonthDays,
  SimpleCalendarDay
} from '../../utils/DateUtil'
import { AppColors } from '../../utils/AppColors'

@Component
export struct PlanDateTimeSelector {
  @Prop themeColor: string = AppColors.BLUE

  @Prop planDate: string = ''
  @Prop planStartTime: string = ''
  @Prop planEndTime: string = ''

  onDateChange: (dateText: string) => void = (dateText: string) => {}
  onStartTimeChange: (timeText: string) => void = (timeText: string) => {}
  onEndTimeChange: (timeText: string) => void = (timeText: string) => {}

  @State showDatePicker: boolean = false
  @State pickerYear: number = 0
  @State pickerMonth: number = 0

  @State showTimePicker: boolean = false
  @State timePickerTarget: string = 'Start'

  aboutToAppear(): void {
    let baseDate = this.planDate.length > 0 ? this.planDate : getToday()
    this.pickerYear = getYearFromDate(baseDate)
    this.pickerMonth = getMonthFromDate(baseDate)
  }

  build() {
    Column() {
      this.DateSelector()

      this.TimeSelector()
    }
    .width('100%')
  }

  @Builder
  DateSelector() {
    Column() {
      Row() {
        Column() {
          Text('计划日期')
            .fontSize(13)
            .fontColor(AppColors.GRAY_500)
            .margin({ bottom: 4 })

          Text(this.planDate.length > 0 ? this.planDate : '请选择日期')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.planDate.length > 0 ? AppColors.GRAY_900 : AppColors.GRAY_400)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.showDatePicker ? '收起' : '选择')
          .fontSize(14)
          .fontColor(this.themeColor)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
      .backgroundColor(AppColors.GRAY_50)
      .borderRadius(12)
      .onClick(() => {
        let baseDate = this.planDate.length > 0 ? this.planDate : getToday()
        this.pickerYear = getYearFromDate(baseDate)
        this.pickerMonth = getMonthFromDate(baseDate)

        animateTo({
          duration: 220,
          curve: Curve.EaseOut
        }, () => {
          this.showDatePicker = !this.showDatePicker
          if (this.showDatePicker) {
            this.showTimePicker = false
          }
        })
      })

      if (this.showDatePicker) {
        this.DatePickerPanel()
      }
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  DatePickerPanel() {
    Column() {
      Row() {
        Button('<')
          .width(42)
          .height(34)
          .fontSize(16)
          .backgroundColor(AppColors.GRAY_200)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(10)
          .onClick(() => {
            this.goPreviousPickerMonth()
          })

        Blank()

        Text(this.pickerYear.toString() + '年' + this.pickerMonth.toString() + '月')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)

        Blank()

        Button('>')
          .width(42)
          .height(34)
          .fontSize(16)
          .backgroundColor(AppColors.GRAY_200)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(10)
          .onClick(() => {
            this.goNextPickerMonth()
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        ForEach(getWeekTitles(), (item: string) => {
          Text(item)
            .width('14.28%')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_500)
            .textAlign(TextAlign.Center)
        }, (item: string) => item)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Grid() {
        ForEach(this.getPickerDays(), (day: SimpleCalendarDay) => {
          GridItem() {
            Text(day.day.toString())
              .width('100%')
              .height(34)
              .fontSize(14)
              .fontWeight(day.date === this.planDate ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.getPickerDayTextColor(day))
              .textAlign(TextAlign.Center)
              .backgroundColor(day.date === this.planDate ? this.themeColor : AppColors.WHITE)
              .borderRadius(10)
              .border({
                width: day.date === getToday() && day.date !== this.planDate ? 1 : 0,
                color: AppColors.GREEN,
                style: BorderStyle.Solid
              })
              .onClick(() => {
                this.selectPlanDate(day.date)
              })
          }
        }, (day: SimpleCalendarDay) => day.date + '_' + day.isCurrentMonth.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(6)
      .columnsGap(6)
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(14)
    .margin({ top: 10 })
    .transition({
      type: TransitionType.All,
      opacity: 0,
      translate: { x: 0, y: -10 }
    })
  }

  @Builder
  TimeSelector() {
    Column() {
      Row() {
        Column() {
          Text('开始时间')
            .fontSize(13)
            .fontColor(AppColors.GRAY_500)
            .margin({ bottom: 4 })

          Text(this.planStartTime.length > 0 ? this.planStartTime : '请选择')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.planStartTime.length > 0 ? AppColors.GRAY_900 : AppColors.GRAY_400)
        }
        .layoutWeight(1)
        .height(56)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(this.timePickerTarget === 'Start' && this.showTimePicker ? AppColors.INDIGO_50 : AppColors.GRAY_50)
        .borderRadius(12)
        .margin({ right: 6 })
        .onClick(() => {
          this.openPlanTimePicker('Start')
        })

        Column() {
          Text('结束时间')
            .fontSize(13)
            .fontColor(AppColors.GRAY_500)
            .margin({ bottom: 4 })

          Text(this.planEndTime.length > 0 ? this.planEndTime : '请选择')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.planEndTime.length > 0 ? AppColors.GRAY_900 : AppColors.GRAY_400)
        }
        .layoutWeight(1)
        .height(56)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(this.timePickerTarget === 'End' && this.showTimePicker ? AppColors.INDIGO_50 : AppColors.GRAY_50)
        .borderRadius(12)
        .margin({ left: 6 })
        .onClick(() => {
          this.openPlanTimePicker('End')
        })
      }
      .width('100%')

      if (this.showTimePicker) {
        this.TimePickerPanel()
      }
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  TimePickerPanel() {
    Column() {
      Row() {
        Text(this.timePickerTarget === 'Start' ? '选择开始时间' : '选择结束时间')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)
          .layoutWeight(1)

        Text(this.getCurrentTargetTime())
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColor)
          .margin({ right: 12 })

        Text('完成')
          .fontSize(13)
          .fontColor(this.themeColor)
          .onClick(() => {
            this.showTimePicker = false
          })
      }
      .width('100%')
      .margin({ bottom: 10 })

      Row() {
        Column() {
          Text('小时')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_500)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 6 })

          List() {
            ForEach(this.getLongHourOptions(), (hour: string, index: number) => {
              ListItem() {
                this.HourOptionItem(hour)
              }
            }, (hour: string, index: number) => hour + '_' + index.toString())
          }
          .width('100%')
          .height(180)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(12)
        }
        .layoutWeight(1)
        .margin({ right: 6 })

        Column() {
          Text('分钟')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_500)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 6 })

          List() {
            ForEach(this.getLongMinuteOptions(), (minute: string, index: number) => {
              ListItem() {
                this.MinuteOptionItem(minute)
              }
            }, (minute: string, index: number) => minute + '_' + index.toString())
          }
          .width('100%')
          .height(180)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(12)
        }
        .layoutWeight(1)
        .margin({ left: 6 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(14)
    .margin({ top: 10 })
    .transition({
      type: TransitionType.All,
      opacity: 0,
      translate: { x: 0, y: -10 }
    })
  }

  @Builder
  HourOptionItem(hour: string) {
    Text(hour)
      .width('100%')
      .height(36)
      .fontSize(15)
      .fontWeight(this.getCurrentTargetHour() === hour ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.getCurrentTargetHour() === hour ? AppColors.WHITE : AppColors.GRAY_900)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.getCurrentTargetHour() === hour ? this.themeColor : AppColors.WHITE)
      .borderRadius(10)
      .margin({ bottom: 6 })
      .onClick(() => {
        this.selectPlanHour(hour)
      })
  }

  @Builder
  MinuteOptionItem(minute: string) {
    Text(minute)
      .width('100%')
      .height(36)
      .fontSize(15)
      .fontWeight(this.getCurrentTargetMinute() === minute ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.getCurrentTargetMinute() === minute ? AppColors.WHITE : AppColors.GRAY_900)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.getCurrentTargetMinute() === minute ? this.themeColor : AppColors.WHITE)
      .borderRadius(10)
      .margin({ bottom: 6 })
      .onClick(() => {
        this.selectPlanMinute(minute)
      })
  }

  getPickerDays(): SimpleCalendarDay[] {
    return buildMonthDays(this.pickerYear, this.pickerMonth, 5)
  }

  selectPlanDate(dateText: string): void {
    this.onDateChange(dateText)
    this.pickerYear = getYearFromDate(dateText)
    this.pickerMonth = getMonthFromDate(dateText)

    animateTo({
      duration: 180,
      curve: Curve.EaseOut
    }, () => {
      this.showDatePicker = false
    })
  }

  goPreviousPickerMonth(): void {
    if (this.pickerMonth === 1) {
      this.pickerYear = this.pickerYear - 1
      this.pickerMonth = 12
    } else {
      this.pickerMonth = this.pickerMonth - 1
    }
  }

  goNextPickerMonth(): void {
    if (this.pickerMonth === 12) {
      this.pickerYear = this.pickerYear + 1
      this.pickerMonth = 1
    } else {
      this.pickerMonth = this.pickerMonth + 1
    }
  }

  getPickerDayTextColor(day: SimpleCalendarDay): string {
    if (day.date === this.planDate) {
      return AppColors.WHITE
    }

    if (!day.isCurrentMonth) {
      return AppColors.GRAY_400
    }

    if (day.date === getToday()) {
      return AppColors.GREEN
    }

    return AppColors.GRAY_900
  }

  openPlanTimePicker(target: string): void {
    if (this.timePickerTarget === target) {
      this.showTimePicker = !this.showTimePicker
    } else {
      this.timePickerTarget = target
      this.showTimePicker = true
    }

    if (this.showTimePicker) {
      this.showDatePicker = false
      this.ensureTargetTimeInitialized()
    }
  }

  ensureTargetTimeInitialized(): void {
    let startTime = this.planStartTime.length === 0 ? '09:00' : this.planStartTime
    let endTime = this.planEndTime.length === 0 ? this.getTimeAfter(startTime, 60) : this.planEndTime

    if (this.planStartTime.length === 0) {
      this.onStartTimeChange(startTime)
    }

    if (this.planEndTime.length === 0) {
      this.onEndTimeChange(endTime)
    }
  }

  getCurrentTargetTime(): string {
    if (this.timePickerTarget === 'Start') {
      if (this.planStartTime.length === 0) {
        return '09:00'
      }
      return this.planStartTime
    }

    if (this.planEndTime.length === 0) {
      return '10:00'
    }
    return this.planEndTime
  }

  getCurrentTargetHour(): string {
    let time = this.getCurrentTargetTime()
    if (time.length < 5) {
      return '09'
    }

    return time.substring(0, 2)
  }

  getCurrentTargetMinute(): string {
    let time = this.getCurrentTargetTime()
    if (time.length < 5) {
      return '00'
    }

    return time.substring(3, 5)
  }

  getLongHourOptions(): string[] {
    let baseList: string[] = []
    let result: string[] = []

    for (let hour = 0; hour < 24; hour++) {
      let hourText = hour < 10 ? '0' + hour.toString() : hour.toString()
      baseList.push(hourText)
    }

    for (let round = 0; round < 8; round++) {
      baseList.forEach((item: string) => {
        result.push(item)
      })
    }

    return result
  }

  getLongMinuteOptions(): string[] {
    let baseList: string[] = []
    let result: string[] = []

    for (let minute = 0; minute < 60; minute++) {
      let minuteText = minute < 10 ? '0' + minute.toString() : minute.toString()
      baseList.push(minuteText)
    }

    for (let round = 0; round < 6; round++) {
      baseList.forEach((item: string) => {
        result.push(item)
      })
    }

    return result
  }

  selectPlanHour(hour: string): void {
    let minute = this.getCurrentTargetMinute()
    this.setTargetTime(hour + ':' + minute)
  }

  selectPlanMinute(minute: string): void {
    let hour = this.getCurrentTargetHour()
    this.setTargetTime(hour + ':' + minute)
  }

  setTargetTime(time: string): void {
    if (this.timePickerTarget === 'Start') {
      this.onStartTimeChange(time)

      if (this.planEndTime.length === 0 || !this.isTimeAfter(this.planEndTime, time)) {
        this.onEndTimeChange(this.getTimeAfter(time, 60))
      }
    } else {
      this.onEndTimeChange(time)

      if (this.planStartTime.length === 0 || !this.isTimeAfter(time, this.planStartTime)) {
        this.onStartTimeChange(this.getTimeAfter(time, -60))
      }
    }
  }

  isTimeAfter(timeA: string, timeB: string): boolean {
    return this.timeToMinute(timeA) > this.timeToMinute(timeB)
  }

  timeToMinute(time: string): number {
    if (time.length < 5) {
      return -1
    }

    let hour = Number(time.substring(0, 2))
    let minute = Number(time.substring(3, 5))

    if (isNaN(hour) || isNaN(minute)) {
      return -1
    }

    return hour * 60 + minute
  }

  getTimeAfter(time: string, offsetMinute: number): string {
    let value = this.timeToMinute(time)

    if (value < 0) {
      return ''
    }

    let finalValue = value + offsetMinute

    while (finalValue < 0) {
      finalValue = finalValue + 24 * 60
    }

    while (finalValue >= 24 * 60) {
      finalValue = finalValue - 24 * 60
    }

    let hour = Math.floor(finalValue / 60)
    let minute = finalValue % 60

    let hourText = hour < 10 ? '0' + hour.toString() : hour.toString()
    let minuteText = minute < 10 ? '0' + minute.toString() : minute.toString()

    return hourText + ':' + minuteText
  }
}
