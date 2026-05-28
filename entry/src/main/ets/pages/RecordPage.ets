import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { RecordItem } from '../model/AppModels'
import { PlanDateTimeSelector } from '../components/plan/PlanDateTimeSelector'
import { RECORDS_KEY, RECORD_NEXT_ID_KEY } from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { getToday, normalizeDateInput } from '../utils/DateUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct RecordPage {
  @Prop themeColor: string = AppColors.BLUE
  @Prop @Watch('onDataRefreshVersionChange') dataRefreshVersion: number = 0

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  @State records: RecordItem[] = []
  @State recordNextId: number = 1
  @State showAddPanel: boolean = false
  @State operationTip: string = '记录生活中的重要瞬间，可添加文字和相册图片。'

  @State editingRecordId: number = -1
  @State recordTitle: string = ''
  @State recordContent: string = ''
  @State recordDate: string = ''
  @State recordTime: string = ''
  @State recordImageUris: string[] = []
  @State isSelectingImage: boolean = false

  aboutToAppear(): void {
    this.resetFormTimeIfEmpty()
    this.initPreferencesAndLoad().then(() => {
      console.info('时光记数据加载完成')
    }).catch(() => {
      this.operationTip = '时光记数据加载失败'
    })
  }

  onDataRefreshVersionChange(): void {
    this.loadRecords().then(() => {
      this.showAddPanel = false
      this.editingRecordId = -1
      this.resetForm()
      this.operationTip = '时光记已同步最新本地数据'
    }).catch(() => {
      this.operationTip = '时光记同步失败'
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('时光记')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('按时间记录生活片段，支持标题、文字和图片')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
          .margin({ bottom: 8 })

        Text(this.operationTip)
          .fontSize(13)
          .fontColor(this.themeColor)
          .margin({ bottom: 18 })

        // Column() {
        //   Text('记录概览')
        //     .fontSize(20)
        //     .fontWeight(FontWeight.Bold)
        //     .fontColor(AppColors.GRAY_900)
        //     .margin({ bottom: 14 })
        //
        //   Row() {
        //     this.SimpleStat('全部记录', this.records.length.toString())
        //     this.SimpleStat('今日记录', this.getTodayRecordCount().toString())
        //     this.SimpleStat('图片数量', this.getImageCount().toString())
        //   }
        //   .width('100%')
        //   .justifyContent(FlexAlign.SpaceBetween)
        // }
        // .width('100%')
        // .padding(18)
        // .backgroundColor(AppColors.CARD_BG)
        // .borderRadius(18)
        // .margin({ bottom: 18 })

        Button(this.getPanelToggleText())
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            if (this.showAddPanel) {
              this.closeRecordPanel()
            } else {
              this.startNewRecord()
            }
          })

        if (this.showAddPanel) {
          this.RecordEditPanel()
        }

        Column() {
          Text('时光列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getSortedRecords().length === 0) {
            Column() {
              Text('暂无时光记录')
                .fontSize(16)
                .fontColor(AppColors.GRAY_400)
                .margin({ top: 20, bottom: 6 })

              Text('点击“新增时光记录”，记录当下的文字或图片。')
                .fontSize(13)
                .fontColor(AppColors.GRAY_400)
                .margin({ bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.getSortedRecords(), (item: RecordItem) => {
              this.RecordTimelineItem(item)
            }, (item: RecordItem) => item.id.toString() + '_' + item.title + '_' + item.date + '_' + item.time + '_' + item.imageUris.length.toString() + '_' + item.createTime.toString())
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BG)
  }

  @Builder
  SimpleStat(title: string, value: string) {
    Column() {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor)

      Text(title)
        .fontSize(12)
        .fontColor(AppColors.GRAY_500)
        .margin({ top: 4 })
    }
    .width('31%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(AppColors.SURFACE_BG)
    .borderRadius(14)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  RecordEditPanel() {
    Column() {
      Text(this.editingRecordId > 0 ? '编辑记录' : '新增记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
        .margin({ bottom: 12 })

      TextInput({ text: this.recordTitle, placeholder: '请输入标题（必填）' })
        .width('100%')
        .height(44)
        .fontColor(AppColors.INPUT_TEXT)
        .placeholderColor(AppColors.INPUT_PLACEHOLDER)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.recordTitle = value
        })

      TextInput({ text: this.recordContent, placeholder: '请输入文字内容' })
        .width('100%')
        .height(96)
        .fontColor(AppColors.INPUT_TEXT)
        .placeholderColor(AppColors.INPUT_PLACEHOLDER)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.recordContent = value
        })

      PlanDateTimeSelector({
        themeColor: this.themeColor,
        planDate: this.recordDate,
        planStartTime: this.recordTime,
        planEndTime: '',
        dateLabel: '记录日期',
        startTimeLabel: '记录时间',
        endTimeLabel: '结束时间',
        showEndTime: false,
        onDateChange: (dateText: string) => {
          this.recordDate = dateText
        },
        onStartTimeChange: (timeText: string) => {
          this.recordTime = timeText
        }
      })

      Row() {
        Button(this.isSelectingImage ? '正在打开相册...' : '从相册选择图片')
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .backgroundColor(AppColors.BORDER_BG)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(12)
          .enabled(!this.isSelectingImage)
          .onClick(() => {
            this.selectImages()
          })

        Button('清空图片')
          .width(92)
          .height(42)
          .fontSize(15)
          .backgroundColor(AppColors.GRAY_400)
          .borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => {
            this.recordImageUris = []
            this.operationTip = '已清空本次选择的图片'
          })
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.recordImageUris.length > 0) {
        this.SelectedImagePreview()
      }

      Button(this.editingRecordId > 0 ? '保存修改' : '保存记录')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.themeColor)
        .borderRadius(12)
        .margin({ top: 4 })
        .onClick(() => {
          this.saveRecord()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(18)
    .margin({ bottom: 18 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SelectedImagePreview() {
    Column() {
      Text('已选择 ' + this.recordImageUris.length.toString() + ' 张图片')
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.recordImageUris, (uri: string) => {
          Image(uri)
            .width('31%')
            .height(86)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .margin({ right: 6, bottom: 6 })
        }, (uri: string) => uri)
      }
      .width('100%')
    }
    .width('100%')
    .padding(10)
    .backgroundColor(AppColors.SURFACE_BG)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RecordTimelineItem(item: RecordItem) {
    Row() {
      Column() {
        Column() {
          Text(this.getMonthText(item.date))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
            .width('100%')
            .textAlign(TextAlign.Center)
            .backgroundColor(this.themeColor)
            .padding({ top: 4, bottom: 4 })

          Text(this.getDayText(item.date))
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 4 })

          Text(this.getWeekText(item.date))
            .fontSize(12)
            .fontColor(AppColors.GRAY_500)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 4 })
        }
        .width(70)
        .backgroundColor(AppColors.SURFACE_BG)
        .borderRadius(14)
        .clip(true)
        .border({ width: 1, color: this.themeColor })

        Blank()
          .width(2)
          .height(24)
          .backgroundColor(this.themeColor)
          .margin({ top: 4 })
      }
      .width(78)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(item.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .layoutWeight(1)

          Text(item.time)
            .fontSize(15)
            .fontColor(AppColors.GRAY_500)
        }
        .width('100%')
        .margin({ bottom: 8 })

        if (item.content.length > 0) {
          Text(item.content)
            .width('100%')
            .fontSize(16)
            .fontColor(AppColors.GRAY_900)
            .lineHeight(24)
            .backgroundColor(AppColors.SURFACE_BG)
            .borderRadius(12)
            .padding(14)
            .margin({ bottom: 10 })
        }

        if (item.imageUris.length > 0) {
          this.RecordImageGrid(item)
        }

        Row() {
          Blank()

          Button('编辑')
            .width(72)
            .height(34)
            .fontSize(13)
            .backgroundColor(AppColors.BORDER_BG)
            .fontColor(AppColors.GRAY_900)
            .borderRadius(10)
            .margin({ right: 8 })
            .onClick(() => {
              this.editRecord(item)
            })

          Button('删除')
            .width(72)
            .height(34)
            .fontSize(13)
            .backgroundColor(AppColors.RED)
            .borderRadius(10)
            .onClick(() => {
              this.deleteRecord(item.id)
            })
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .padding({ left: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  RecordImageGrid(item: RecordItem) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(item.imageUris, (uri: string) => {
        Image(uri)
          .width(item.imageUris.length === 1 ? '100%' : '31%')
          .height(item.imageUris.length === 1 ? 180 : 92)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ right: 6, bottom: 6 })
      }, (uri: string) => uri)
    }
    .width('100%')
    .margin({ bottom: 4 })
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadRecords()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }
    this.dataPreferences = await getTimePlanPreferences(this.context)
  }

  async loadRecords(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    let recordsValue = await this.dataPreferences.get(RECORDS_KEY, '[]')
    if (typeof recordsValue === 'string') {
      this.records = this.normalizeRecords(this.parseRecordArray(recordsValue))
    } else {
      this.records = []
    }

    let nextIdValue = await this.dataPreferences.get(RECORD_NEXT_ID_KEY, 1)
    if (typeof nextIdValue === 'number' && nextIdValue > 0) {
      this.recordNextId = Math.floor(nextIdValue)
    } else {
      this.recordNextId = this.getMaxRecordId(this.records) + 1
    }

    if (this.recordNextId <= this.getMaxRecordId(this.records)) {
      this.recordNextId = this.getMaxRecordId(this.records) + 1
    }
  }

  parseRecordArray(text: string): RecordItem[] {
    try {
      let parsed = JSON.parse(text) as RecordItem[]
      if (Array.isArray(parsed)) {
        return parsed
      }
    } catch (error) {
      console.error('时光记数据解析失败')
    }
    return []
  }

  normalizeRecords(list: RecordItem[]): RecordItem[] {
    let result: RecordItem[] = []
    list.forEach((item: RecordItem) => {
      let images: string[] = []
      if (Array.isArray(item.imageUris)) {
        item.imageUris.forEach((uri: string) => {
          if (typeof uri === 'string' && uri.length > 0) {
            images.push(uri)
          }
        })
      }

      result.push({
        id: this.safeNumber(item.id, 0),
        title: this.safeString(item.title, '未命名记录'),
        content: this.safeString(item.content, ''),
        date: normalizeDateInput(this.safeString(item.date, getToday())),
        time: this.normalizeTime(this.safeString(item.time, this.getCurrentTimeText())),
        imageUris: images,
        createTime: this.safeNumber(item.createTime, new Date().getTime())
      })
    })
    return result
  }

  startNewRecord(): void {
    this.editingRecordId = -1
    this.resetForm()
    this.showAddPanel = true
    this.operationTip = '正在新增时光记录'
  }

  closeRecordPanel(): void {
    this.showAddPanel = false
    this.editingRecordId = -1
    this.resetForm()
    this.operationTip = '已收起记录表单'
  }

  editRecord(item: RecordItem): void {
    this.editingRecordId = item.id
    this.recordTitle = item.title
    this.recordContent = item.content
    this.recordDate = normalizeDateInput(item.date)
    this.recordTime = this.normalizeTime(item.time)
    this.recordImageUris = this.cloneStringArray(item.imageUris)
    this.showAddPanel = true
    this.operationTip = '正在编辑“' + item.title + '”'
  }

  saveRecord(): void {
    this.saveRecordAsync().then(() => {
      console.info('保存时光记录成功')
    }).catch(() => {
      this.operationTip = '保存记录失败，请稍后重试'
    })
  }

  async saveRecordAsync(): Promise<void> {
    if (this.recordTitle.trim().length === 0) {
      this.operationTip = '标题为必填项，请先填写标题'
      return
    }

    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      this.operationTip = '无法打开本地存储'
      return
    }

    if (this.editingRecordId > 0) {
      await this.updateCurrentRecord()
      return
    }

    await this.addNewRecord()
  }

  async addNewRecord(): Promise<void> {
    let record: RecordItem = {
      id: this.recordNextId,
      title: this.recordTitle.trim(),
      content: this.recordContent.trim(),
      date: normalizeDateInput(this.recordDate),
      time: this.normalizeTime(this.recordTime),
      imageUris: this.cloneStringArray(this.recordImageUris),
      createTime: new Date().getTime()
    }

    let nextRecords = this.cloneRecordArray(this.records)
    nextRecords.push(record)
    this.records = nextRecords
    this.recordNextId = this.recordNextId + 1
    await this.saveRecords()
    this.resetForm()
    this.showAddPanel = false
    this.editingRecordId = -1
    this.operationTip = '已保存一条新的时光记录'
  }

  async updateCurrentRecord(): Promise<void> {
    let found = false
    let nextRecords: RecordItem[] = []
    this.records.forEach((item: RecordItem) => {
      if (item.id === this.editingRecordId) {
        found = true
        nextRecords.push({
          id: item.id,
          title: this.recordTitle.trim(),
          content: this.recordContent.trim(),
          date: normalizeDateInput(this.recordDate),
          time: this.normalizeTime(this.recordTime),
          imageUris: this.cloneStringArray(this.recordImageUris),
          createTime: item.createTime
        })
      } else {
        nextRecords.push(item)
      }
    })

    if (!found) {
      this.operationTip = '未找到要编辑的记录'
      this.editingRecordId = -1
      return
    }

    this.records = nextRecords
    await this.saveRecords()
    this.resetForm()
    this.showAddPanel = false
    this.editingRecordId = -1
    this.operationTip = '已保存时光记录修改'
  }

  deleteRecord(recordId: number): void {
    this.deleteRecordAsync(recordId).then(() => {
      console.info('删除时光记录成功')
    }).catch(() => {
      this.operationTip = '删除记录失败，请稍后重试'
    })
  }

  async deleteRecordAsync(recordId: number): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }
    this.records = this.records.filter((item: RecordItem) => {
      return item.id !== recordId
    })
    if (this.editingRecordId === recordId) {
      this.showAddPanel = false
      this.editingRecordId = -1
      this.resetForm()
    }
    await this.saveRecords()
    this.operationTip = '已删除时光记录'
  }

  async saveRecords(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }
    await this.dataPreferences.put(RECORDS_KEY, JSON.stringify(this.records))
    await this.dataPreferences.put(RECORD_NEXT_ID_KEY, this.recordNextId)
    await this.dataPreferences.flush()
  }

  selectImages(): void {
    this.selectImagesAsync().then(() => {
      console.info('相册图片选择完成')
    }).catch((error: BusinessError) => {
      this.isSelectingImage = false
      this.operationTip = '图片选择失败：' + this.getErrorMessage(error)
    })
  }

  async selectImagesAsync(): Promise<void> {
    this.isSelectingImage = true
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
    photoSelectOptions.maxSelectNumber = 9

    const photoViewPicker = new photoAccessHelper.PhotoViewPicker()
    let photoSelectResult = await photoViewPicker.select(photoSelectOptions)
    this.isSelectingImage = false

    if (photoSelectResult.photoUris.length <= 0) {
      this.operationTip = '未选择图片'
      return
    }

    this.recordImageUris = photoSelectResult.photoUris
    this.operationTip = '已选择 ' + this.recordImageUris.length.toString() + ' 张图片'
  }

  resetForm(): void {
    this.recordTitle = ''
    this.recordContent = ''
    this.recordImageUris = []
    this.recordDate = getToday()
    this.recordTime = this.getCurrentTimeText()
  }

  resetFormTimeIfEmpty(): void {
    if (this.recordDate.trim().length === 0) {
      this.recordDate = getToday()
    }
    if (this.recordTime.trim().length === 0) {
      this.recordTime = this.getCurrentTimeText()
    }
  }

  getPanelToggleText(): string {
    if (this.showAddPanel && this.editingRecordId > 0) {
      return '取消编辑'
    }
    if (this.showAddPanel) {
      return '取消'
    }
    return '+ 新增时光记录'
  }

  getSortedRecords(): RecordItem[] {
    let list: RecordItem[] = []
    this.records.forEach((item: RecordItem) => {
      list.push(item)
    })

    list.sort((a: RecordItem, b: RecordItem) => {
      let left = a.date + ' ' + a.time
      let right = b.date + ' ' + b.time
      if (left < right) {
        return 1
      }
      if (left > right) {
        return -1
      }
      return b.id - a.id
    })
    return list
  }

  getTodayRecordCount(): number {
    let today = getToday()
    return this.records.filter((item: RecordItem) => {
      return item.date === today
    }).length
  }

  getImageCount(): number {
    let count = 0
    this.records.forEach((item: RecordItem) => {
      count = count + item.imageUris.length
    })
    return count
  }

  getMaxRecordId(list: RecordItem[]): number {
    let maxId = 0
    list.forEach((item: RecordItem) => {
      if (item.id > maxId) {
        maxId = item.id
      }
    })
    return maxId
  }

  getMonthText(dateText: string): string {
    if (dateText.length >= 7) {
      return Number(dateText.substring(5, 7)).toString() + '月'
    }
    return '本月'
  }

  getDayText(dateText: string): string {
    if (dateText.length >= 10) {
      return Number(dateText.substring(8, 10)).toString()
    }
    return '--'
  }

  getWeekText(dateText: string): string {
    let weekList: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    if (dateText.length < 10) {
      return '周--'
    }
    let year = Number(dateText.substring(0, 4))
    let month = Number(dateText.substring(5, 7))
    let day = Number(dateText.substring(8, 10))
    let date = new Date(year, month - 1, day)
    return weekList[date.getDay()]
  }

  getCurrentTimeText(): string {
    let now = new Date()
    return this.pad2(now.getHours()) + ':' + this.pad2(now.getMinutes())
  }

  normalizeTime(value: string): string {
    let raw = value.trim()
    if (raw.length === 0) {
      return this.getCurrentTimeText()
    }

    raw = raw.replace('：', ':')
    if (raw.indexOf(':') < 0) {
      let onlyNumber = Number(raw)
      if (!isNaN(onlyNumber) && onlyNumber >= 0 && onlyNumber <= 23) {
        return this.pad2(Math.floor(onlyNumber)) + ':00'
      }
      return raw
    }

    let parts = raw.split(':')
    let hour = Number(parts[0])
    let minute = Number(parts[1])
    if (isNaN(hour) || isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return this.getCurrentTimeText()
    }
    return this.pad2(Math.floor(hour)) + ':' + this.pad2(Math.floor(minute))
  }

  pad2(value: number): string {
    if (value < 10) {
      return '0' + value.toString()
    }
    return value.toString()
  }

  safeString(value: string, defaultValue: string): string {
    if (typeof value === 'string') {
      return value
    }
    return defaultValue
  }

  safeNumber(value: number, defaultValue: number): number {
    if (typeof value === 'number' && value >= 0) {
      return value
    }
    return defaultValue
  }

  cloneStringArray(list: string[]): string[] {
    let result: string[] = []
    list.forEach((item: string) => {
      result.push(item)
    })
    return result
  }

  cloneRecordArray(list: RecordItem[]): RecordItem[] {
    let result: RecordItem[] = []
    list.forEach((item: RecordItem) => {
      result.push(item)
    })
    return result
  }

  getErrorMessage(error: BusinessError): string {
    if (error !== null && error !== undefined && error.message !== undefined && error.message.length > 0) {
      return error.message
    }
    return '请稍后重试'
  }
}
