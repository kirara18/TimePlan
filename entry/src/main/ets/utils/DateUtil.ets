export interface SimpleCalendarDay {
  date: string
  day: number
  isCurrentMonth: boolean
}

export function safeText(value: string | undefined | null, defaultValue: string): string {
  if (value === undefined || value === null || value.length === 0) {
    return defaultValue
  }
  return value
}

export function getToday(): string {
  let date = new Date()
  return formatDate(date.getFullYear(), date.getMonth() + 1, date.getDate())
}

export function getCurrentYear(): number {
  let date = new Date()
  return date.getFullYear()
}

export function getCurrentMonth(): number {
  let date = new Date()
  return date.getMonth() + 1
}

export function formatDate(year: number, month: number, day: number): string {
  let monthText = month < 10 ? '0' + month.toString() : month.toString()
  let dayText = day < 10 ? '0' + day.toString() : day.toString()
  return year.toString() + '-' + monthText + '-' + dayText
}

export function formatMonth(year: number, month: number): string {
  let monthText = month < 10 ? '0' + month.toString() : month.toString()
  return year.toString() + '-' + monthText
}

export function getYearFromDate(dateText: string): number {
  return Number(dateText.substring(0, 4))
}

export function getMonthFromDate(dateText: string): number {
  return Number(dateText.substring(5, 7))
}

export function getWeekTitles(): string[] {
  return ['日', '一', '二', '三', '四', '五', '六']
}

export function dateInList(dateText: string, list: string[]): boolean {
  return list.indexOf(dateText) >= 0
}

export function dateToDayNumber(dateText: string): number {
  let year = Number(dateText.substring(0, 4))
  let month = Number(dateText.substring(5, 7))
  let day = Number(dateText.substring(8, 10))

  // 使用 UTC 计算“日期序号”，避免时区换算导致日期前后偏移。
  let time = Date.UTC(year, month - 1, day)
  return Math.floor(time / 86400000)
}

export function dayNumberToDate(dayNumber: number): string {
  // 使用 UTC 读取年月日，保证日期加减不受本地时区影响。
  let date = new Date(dayNumber * 86400000)
  let year = date.getUTCFullYear()
  let month = date.getUTCMonth() + 1
  let day = date.getUTCDate()
  return formatDate(year, month, day)
}

export function addDays(dateText: string, count: number): string {
  return dayNumberToDate(dateToDayNumber(dateText) + count)
}

export function isValidDateParts(year: number, month: number, day: number): boolean {
  if (isNaN(year) || isNaN(month) || isNaN(day)) {
    return false
  }

  if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false
  }

  let date = new Date(year, month - 1, day)
  return date.getFullYear() === year && date.getMonth() + 1 === month && date.getDate() === day
}

export function normalizeDateInput(value: string, baseYear?: number, baseMonth?: number): string {
  let raw = safeText(value, '').trim()

  if (raw.length === 0 || raw === '未设置') {
    return getToday()
  }

  if (raw === '今天') {
    return getToday()
  }

  if (raw === '明天') {
    return addDays(getToday(), 1)
  }

  raw = raw.replace('年', '-')
  raw = raw.replace('月', '-')
  raw = raw.replace('日', '')
  raw = raw.replace('号', '')
  raw = raw.replace('/', '-')
  raw = raw.replace('.', '-')

  let parts = raw.split('-')

  if (parts.length === 1) {
    let day = Number(parts[0])
    let now = new Date()
    let year = baseYear === undefined ? now.getFullYear() : baseYear
    let month = baseMonth === undefined ? now.getMonth() + 1 : baseMonth

    if (isValidDateParts(year, month, Math.floor(day))) {
      return formatDate(year, month, Math.floor(day))
    }
  }

  if (parts.length === 2) {
    let month = Number(parts[0])
    let day = Number(parts[1])
    let now = new Date()
    let year = baseYear === undefined ? now.getFullYear() : baseYear

    if (isValidDateParts(year, Math.floor(month), Math.floor(day))) {
      return formatDate(year, Math.floor(month), Math.floor(day))
    }
  }

  if (parts.length >= 3) {
    let year = Number(parts[0])
    let month = Number(parts[1])
    let day = Number(parts[2])

    if (isValidDateParts(Math.floor(year), Math.floor(month), Math.floor(day))) {
      return formatDate(Math.floor(year), Math.floor(month), Math.floor(day))
    }
  }

  return getToday()
}

export function buildMonthDays(year: number, month: number, minRows: number = 5): SimpleCalendarDay[] {
  let list: SimpleCalendarDay[] = []

  let firstWeek = new Date(year, month - 1, 1).getDay()
  let daysInMonth = new Date(year, month, 0).getDate()

  let prevYear = month === 1 ? year - 1 : year
  let prevMonth = month === 1 ? 12 : month - 1
  let nextYear = month === 12 ? year + 1 : year
  let nextMonth = month === 12 ? 1 : month + 1
  let daysInPrevMonth = new Date(prevYear, prevMonth, 0).getDate()

  let realCellCount = firstWeek + daysInMonth
  let rowCount = Math.ceil(realCellCount / 7)

  if (rowCount < minRows) {
    rowCount = minRows
  }

  let totalCells = rowCount * 7

  for (let i = 0; i < totalCells; i++) {
    let finalYear = year
    let finalMonth = month
    let finalDay = 1
    let isCurrent = true

    if (i < firstWeek) {
      finalYear = prevYear
      finalMonth = prevMonth
      finalDay = daysInPrevMonth - firstWeek + i + 1
      isCurrent = false
    } else if (i >= firstWeek + daysInMonth) {
      finalYear = nextYear
      finalMonth = nextMonth
      finalDay = i - firstWeek - daysInMonth + 1
      isCurrent = false
    } else {
      finalDay = i - firstWeek + 1
      isCurrent = true
    }

    list.push({
      date: formatDate(finalYear, finalMonth, finalDay),
      day: finalDay,
      isCurrentMonth: isCurrent
    })
  }

  return list
}
