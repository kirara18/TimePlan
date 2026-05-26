import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { picker, fileIo as fs } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'
import { BusinessError } from '@kit.BasicServicesKit'
import { TodoTask, NoteItem, HabitData, FocusRecord } from '../model/AppModels'
import { PlanStorageService } from '../services/PlanStorageService'
import {
  TASKS_KEY,
  TASK_NEXT_ID_KEY,
  NOTES_KEY,
  NOTE_NEXT_ID_KEY,
  HABITS_KEY,
  HABIT_NEXT_ID_KEY,
  FOCUS_RECORDS_KEY,
  FOCUS_NEXT_ID_KEY,
  THEME_KEY
} from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

interface TimePlanBackupData {
  tasks: TodoTask[]
  taskNextId: number
  notes: NoteItem[]
  noteNextId: number
  habits: HabitData[]
  habitNextId: number
  focusRecords: FocusRecord[]
  focusNextId: number
  themeMode: string
}

interface TimePlanBackupFile {
  app: string
  schemaVersion: number
  createdAt: string
  appVersion: string
  data: TimePlanBackupData
}

@Component
export struct DataBackupPage {
  @Prop themeColor: string = AppColors.BLUE
  onBack: () => void = () => {}
  onDataRestored: () => void = () => {}

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null
  pendingBackup: TimePlanBackupFile | null = null

  @State statusText: string = '备份文件会包含计划、便签、习惯打卡、专注记录和主题偏好。'
  @State pendingSummary: string = ''
  @State showRestoreConfirm: boolean = false
  @State isWorking: boolean = false

  build() {
    Stack() {
      Scroll() {
        Column() {
          this.Header('数据备份')

          Column() {
            Text('本地 JSON 备份')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
              .margin({ bottom: 8 })

            Text('通过系统文件选择器导出或恢复备份文件。应用不会上传备份文件，也不会新增存储权限。')
              .fontSize(15)
              .fontColor(AppColors.GRAY_500)
              .lineHeight(24)
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.CARD_BG)
          .borderRadius(18)
          .margin({ bottom: 16 })
          .alignItems(HorizontalAlign.Start)

          this.ActionCard(
            '导出备份',
            '将当前数据保存为 TimePlan_backup_日期.json 文件，由你自行选择保存位置。',
            '导出备份文件',
            'export'
          )

          this.ActionCard(
            '恢复备份',
            '选择之前导出的 JSON 文件，校验通过后覆盖当前应用内的本地数据。',
            '选择备份并恢复',
            'restore'
          )

          Column() {
            Text('状态')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
              .margin({ bottom: 8 })

            Text(this.statusText)
              .fontSize(14)
              .fontColor(AppColors.GRAY_500)
              .lineHeight(22)
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.CARD_BG)
          .borderRadius(18)
          .margin({ bottom: 30 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.PAGE_BG)

      if (this.showRestoreConfirm) {
        Column() {
          Blank()
          this.RestoreConfirmPanel()
          Blank()
        }
        .width('100%')
        .height('100%')
        .padding({ left: 24, right: 24 })
        .backgroundColor('#66000000')
      }
    }
    .width('100%')
    .height('100%')
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
  ActionCard(title: string, description: string, buttonText: string, actionType: string) {
    Column() {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
        .margin({ bottom: 8 })

      Text(description)
        .fontSize(15)
        .fontColor(AppColors.GRAY_500)
        .lineHeight(24)
        .margin({ bottom: 14 })

      Button(buttonText)
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.themeColor)
        .borderRadius(12)
        .enabled(!this.isWorking)
        .opacity(this.isWorking ? 0.6 : 1)
        .onClick(() => {
          if (this.isWorking) {
            return
          }
          if (actionType === 'export') {
            this.exportBackup()
          } else {
            this.selectBackupForRestore()
          }
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(18)
    .margin({ bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RestoreConfirmPanel() {
    Column() {
      Text('确认恢复备份？')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.RED)
        .margin({ bottom: 8 })

      Text(this.pendingSummary)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)
        .lineHeight(22)
        .margin({ bottom: 12 })

      Text('恢复会覆盖当前应用内的计划、便签、习惯打卡、专注记录和主题偏好。当前数据如未备份，将无法在应用内找回。')
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)
        .lineHeight(22)
        .margin({ bottom: 14 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .backgroundColor(AppColors.GRAY_400)
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.pendingBackup = null
            this.showRestoreConfirm = false
            this.statusText = '已取消恢复操作'
          })

        Button('确认恢复')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppColors.RED)
          .borderRadius(12)
          .margin({ left: 8 })
          .enabled(!this.isWorking)
          .onClick(() => {
            if (this.isWorking) {
              return
            }
            this.restorePendingBackup()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(20)
    .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: '#FCA5A5' })
    .alignItems(HorizontalAlign.Start)
  }

  async ensurePreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }
    this.dataPreferences = await getTimePlanPreferences(this.context)
  }

  exportBackup(): void {
    this.exportBackupAsync().then(() => {
      console.info('导出备份完成')
    }).catch((error: BusinessError) => {
      this.isWorking = false
      this.statusText = '导出失败：' + this.getErrorMessage(error)
    })
  }

  async exportBackupAsync(): Promise<void> {
    this.isWorking = true
    this.statusText = '正在整理本地数据...'

    let backupFile = await this.createBackupFile()
    let backupText = JSON.stringify(backupFile, null, 2)

    const documentSaveOptions = new picker.DocumentSaveOptions()
    documentSaveOptions.newFileNames = [this.createBackupFileName()]
    documentSaveOptions.fileSuffixChoices = ['JSON 文件|.json']

    const documentViewPicker = new picker.DocumentViewPicker(this.context)
    let result = await documentViewPicker.save(documentSaveOptions)
    if (result.length <= 0) {
      this.isWorking = false
      this.statusText = '已取消导出操作'
      return
    }

    this.writeTextToUri(result[0], backupText)
    this.isWorking = false
    this.statusText = '备份已导出。请妥善保存该 JSON 文件，避免泄露个人计划和便签内容。'
  }

  selectBackupForRestore(): void {
    this.selectBackupForRestoreAsync().then(() => {
      console.info('选择备份完成')
    }).catch((error: BusinessError) => {
      this.isWorking = false
      this.pendingBackup = null
      this.showRestoreConfirm = false
      this.statusText = '读取备份失败：' + this.getErrorMessage(error)
    })
  }

  async selectBackupForRestoreAsync(): Promise<void> {
    this.isWorking = true
    this.statusText = '请选择 TimePlan 备份文件...'

    const documentSelectOptions = new picker.DocumentSelectOptions()
    documentSelectOptions.maxSelectNumber = 1
    documentSelectOptions.fileSuffixFilters = ['JSON 文件|.json', '*']

    const documentViewPicker = new picker.DocumentViewPicker(this.context)
    let result = await documentViewPicker.select(documentSelectOptions)
    if (result.length <= 0) {
      this.isWorking = false
      this.statusText = '已取消恢复操作'
      return
    }

    let fileText = this.readTextFromUri(result[0])
    let parsedBackup = this.parseBackupText(fileText)
    this.pendingBackup = parsedBackup
    this.pendingSummary = this.createBackupSummary(parsedBackup)
    this.showRestoreConfirm = true
    this.isWorking = false
    this.statusText = '已读取备份文件，请确认是否恢复。'
  }

  restorePendingBackup(): void {
    this.restorePendingBackupAsync().then(() => {
      console.info('恢复备份完成')
    }).catch((error: BusinessError) => {
      this.isWorking = false
      this.statusText = '恢复失败：' + this.getErrorMessage(error)
    })
  }

  async restorePendingBackupAsync(): Promise<void> {
    if (this.pendingBackup === null) {
      this.showRestoreConfirm = false
      this.statusText = '没有可恢复的备份数据'
      return
    }

    this.isWorking = true
    await this.ensurePreferences()
    if (this.dataPreferences === null) {
      this.isWorking = false
      this.statusText = '恢复失败：无法打开本地存储'
      return
    }

    let backupData = this.pendingBackup.data
    await this.dataPreferences.put(TASKS_KEY, JSON.stringify(backupData.tasks))
    await this.dataPreferences.put(TASK_NEXT_ID_KEY, backupData.taskNextId)
    await this.dataPreferences.put(NOTES_KEY, JSON.stringify(backupData.notes))
    await this.dataPreferences.put(NOTE_NEXT_ID_KEY, backupData.noteNextId)
    await this.dataPreferences.put(HABITS_KEY, JSON.stringify(backupData.habits))
    await this.dataPreferences.put(HABIT_NEXT_ID_KEY, backupData.habitNextId)
    await this.dataPreferences.put(FOCUS_RECORDS_KEY, JSON.stringify(backupData.focusRecords))
    await this.dataPreferences.put(FOCUS_NEXT_ID_KEY, backupData.focusNextId)
    await this.dataPreferences.put(THEME_KEY, backupData.themeMode)
    await this.dataPreferences.flush()

    this.pendingBackup = null
    this.showRestoreConfirm = false
    this.isWorking = false
    this.statusText = '恢复成功，其他页面数据已同步刷新。'
    this.onDataRestored()
  }

  async createBackupFile(): Promise<TimePlanBackupFile> {
    await this.ensurePreferences()
    let data = await this.readCurrentBackupData()
    return {
      app: 'TimePlan',
      schemaVersion: 1,
      createdAt: this.formatDateTime(new Date()),
      appVersion: '1.0.0',
      data: data
    }
  }

  async readCurrentBackupData(): Promise<TimePlanBackupData> {
    if (this.dataPreferences === null) {
      return this.createEmptyBackupData()
    }

    let taskText = await this.getPreferenceString(TASKS_KEY, '[]')
    let noteText = await this.getPreferenceString(NOTES_KEY, '[]')
    let habitText = await this.getPreferenceString(HABITS_KEY, '[]')
    let focusText = await this.getPreferenceString(FOCUS_RECORDS_KEY, '[]')
    let themeMode = await this.getPreferenceString(THEME_KEY, '默认蓝色')

    let tasks = PlanStorageService.normalizeTasks(this.parseTaskArray(taskText))
    let notes = PlanStorageService.normalizeNotes(this.parseNoteArray(noteText))
    let habits = PlanStorageService.normalizeChecks(this.parseHabitArray(habitText))
    let focusRecords = this.normalizeFocusRecords(this.parseFocusRecordArray(focusText))

    let taskNextId = this.ensureNextId(await this.getPreferenceNumber(TASK_NEXT_ID_KEY, 1), this.getMaxTaskId(tasks))
    let noteNextId = this.ensureNextId(await this.getPreferenceNumber(NOTE_NEXT_ID_KEY, 1), this.getMaxNoteId(notes))
    let habitNextId = this.ensureNextId(await this.getPreferenceNumber(HABIT_NEXT_ID_KEY, 1), this.getMaxHabitId(habits))
    let focusNextId = this.ensureNextId(await this.getPreferenceNumber(FOCUS_NEXT_ID_KEY, 1), this.getMaxFocusRecordId(focusRecords))

    return {
      tasks: tasks,
      taskNextId: taskNextId,
      notes: notes,
      noteNextId: noteNextId,
      habits: habits,
      habitNextId: habitNextId,
      focusRecords: focusRecords,
      focusNextId: focusNextId,
      themeMode: this.normalizeThemeMode(themeMode)
    }
  }

  createEmptyBackupData(): TimePlanBackupData {
    return {
      tasks: [],
      taskNextId: 1,
      notes: [],
      noteNextId: 1,
      habits: [],
      habitNextId: 1,
      focusRecords: [],
      focusNextId: 1,
      themeMode: '默认蓝色'
    }
  }

  parseBackupText(text: string): TimePlanBackupFile {
    let parsed = JSON.parse(text) as TimePlanBackupFile

    if (parsed.app !== 'TimePlan') {
      throw new Error('不是 TimePlan 备份文件')
    }
    if (parsed.schemaVersion !== 1) {
      throw new Error('暂不支持该备份版本')
    }
    if (parsed.data === null || parsed.data === undefined) {
      throw new Error('备份数据不完整')
    }
    if (!Array.isArray(parsed.data.tasks) || !Array.isArray(parsed.data.notes) ||
      !Array.isArray(parsed.data.habits) || !Array.isArray(parsed.data.focusRecords)) {
      throw new Error('备份数据格式错误')
    }

    let tasks = PlanStorageService.normalizeTasks(parsed.data.tasks)
    let notes = PlanStorageService.normalizeNotes(parsed.data.notes)
    let habits = PlanStorageService.normalizeChecks(parsed.data.habits)
    let focusRecords = this.normalizeFocusRecords(parsed.data.focusRecords)

    return {
      app: 'TimePlan',
      schemaVersion: 1,
      createdAt: this.safeString(parsed.createdAt, this.formatDateTime(new Date())),
      appVersion: this.safeString(parsed.appVersion, '1.0.0'),
      data: {
        tasks: tasks,
        taskNextId: this.ensureNextId(parsed.data.taskNextId, this.getMaxTaskId(tasks)),
        notes: notes,
        noteNextId: this.ensureNextId(parsed.data.noteNextId, this.getMaxNoteId(notes)),
        habits: habits,
        habitNextId: this.ensureNextId(parsed.data.habitNextId, this.getMaxHabitId(habits)),
        focusRecords: focusRecords,
        focusNextId: this.ensureNextId(parsed.data.focusNextId, this.getMaxFocusRecordId(focusRecords)),
        themeMode: this.normalizeThemeMode(parsed.data.themeMode)
      }
    }
  }

  writeTextToUri(uri: string, text: string): void {
    let file = fs.openSync(uri, fs.OpenMode.READ_WRITE)
    fs.writeSync(file.fd, text)
    fs.closeSync(file)
  }

  readTextFromUri(uri: string): string {
    let file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
    let fileSize = fs.statSync(file.fd).size
    if (fileSize <= 0) {
      fs.closeSync(file)
      throw new Error('备份文件为空')
    }
    let buffer = new ArrayBuffer(fileSize)
    let readLength = fs.readSync(file.fd, buffer)
    fs.closeSync(file)

    let decoder = util.TextDecoder.create('UTF-8')
    let uint8Array = new Uint8Array(buffer, 0, readLength)
    return decoder.decodeToString(uint8Array)
  }

  async getPreferenceString(key: string, defaultValue: string): Promise<string> {
    if (this.dataPreferences === null) {
      return defaultValue
    }
    let value = await this.dataPreferences.get(key, defaultValue)
    if (typeof value === 'string') {
      return value
    }
    return defaultValue
  }

  async getPreferenceNumber(key: string, defaultValue: number): Promise<number> {
    if (this.dataPreferences === null) {
      return defaultValue
    }
    let value = await this.dataPreferences.get(key, defaultValue)
    if (typeof value === 'number') {
      return value
    }
    return defaultValue
  }

  parseTaskArray(text: string): TodoTask[] {
    try {
      let parsed = JSON.parse(text) as TodoTask[]
      if (Array.isArray(parsed)) {
        return parsed
      }
    } catch (error) {
      console.error('计划数据解析失败')
    }
    return []
  }

  parseNoteArray(text: string): NoteItem[] {
    try {
      let parsed = JSON.parse(text) as NoteItem[]
      if (Array.isArray(parsed)) {
        return parsed
      }
    } catch (error) {
      console.error('便签数据解析失败')
    }
    return []
  }

  parseHabitArray(text: string): HabitData[] {
    try {
      let parsed = JSON.parse(text) as HabitData[]
      if (Array.isArray(parsed)) {
        return parsed
      }
    } catch (error) {
      console.error('打卡数据解析失败')
    }
    return []
  }

  parseFocusRecordArray(text: string): FocusRecord[] {
    try {
      let parsed = JSON.parse(text) as FocusRecord[]
      if (Array.isArray(parsed)) {
        return parsed
      }
    } catch (error) {
      console.error('专注记录解析失败')
    }
    return []
  }

  normalizeFocusRecords(list: FocusRecord[]): FocusRecord[] {
    let result: FocusRecord[] = []
    list.forEach((item: FocusRecord) => {
      result.push({
        id: this.safeNumber(item.id, 0),
        taskId: this.safeNumber(item.taskId, 0),
        taskTitle: this.safeString(item.taskTitle, '未命名任务'),
        durationMinutes: this.safeNumber(item.durationMinutes, 0),
        date: this.safeString(item.date, ''),
        startTime: this.safeString(item.startTime, ''),
        endTime: this.safeString(item.endTime, ''),
        createTime: this.safeNumber(item.createTime, new Date().getTime())
      })
    })
    return result
  }

  createBackupSummary(backupFile: TimePlanBackupFile): string {
    return '备份时间：' + backupFile.createdAt + '\n' +
      '计划：' + backupFile.data.tasks.length + ' 条，便签：' + backupFile.data.notes.length + ' 条，打卡：' +
      backupFile.data.habits.length + ' 项，专注记录：' + backupFile.data.focusRecords.length + ' 条。'
  }

  createBackupFileName(): string {
    let now = new Date()
    return 'TimePlan_backup_' + now.getFullYear().toString() + this.pad2(now.getMonth() + 1) + this.pad2(now.getDate()) + '_' +
      this.pad2(now.getHours()) + this.pad2(now.getMinutes()) + this.pad2(now.getSeconds()) + '.json'
  }

  formatDateTime(date: Date): string {
    return date.getFullYear().toString() + '-' + this.pad2(date.getMonth() + 1) + '-' + this.pad2(date.getDate()) + ' ' +
      this.pad2(date.getHours()) + ':' + this.pad2(date.getMinutes()) + ':' + this.pad2(date.getSeconds())
  }

  pad2(value: number): string {
    if (value < 10) {
      return '0' + value.toString()
    }
    return value.toString()
  }

  ensureNextId(value: number, maxId: number): number {
    let nextId = 1
    if (typeof value === 'number' && value > 0) {
      nextId = Math.floor(value)
    }
    if (nextId <= maxId) {
      nextId = maxId + 1
    }
    return nextId
  }

  getMaxTaskId(list: TodoTask[]): number {
    let maxId = 0
    list.forEach((item: TodoTask) => {
      if (item.id > maxId) {
        maxId = item.id
      }
    })
    return maxId
  }

  getMaxNoteId(list: NoteItem[]): number {
    let maxId = 0
    list.forEach((item: NoteItem) => {
      if (item.id > maxId) {
        maxId = item.id
      }
    })
    return maxId
  }

  getMaxHabitId(list: HabitData[]): number {
    let maxId = 0
    list.forEach((item: HabitData) => {
      if (item.id > maxId) {
        maxId = item.id
      }
    })
    return maxId
  }

  getMaxFocusRecordId(list: FocusRecord[]): number {
    let maxId = 0
    list.forEach((item: FocusRecord) => {
      if (item.id > maxId) {
        maxId = item.id
      }
    })
    return maxId
  }

  normalizeThemeMode(value: string): string {
    if (value === '清新绿色' || value === '活力红色') {
      return value
    }
    return '默认蓝色'
  }

  safeString(value: string, defaultValue: string): string {
    if (typeof value === 'string' && value.length > 0) {
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

  getErrorMessage(error: BusinessError): string {
    if (error !== null && error !== undefined && error.message !== undefined && error.message.length > 0) {
      return error.message
    }
    return '请检查文件格式或稍后重试'
  }
}
