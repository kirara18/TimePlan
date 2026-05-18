import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { STORE_NAME } from './StoreConstants'

export async function getTimePlanPreferences(context: common.UIAbilityContext): Promise<preferences.Preferences> {
  return await preferences.getPreferences(context, {
    name: STORE_NAME
  })
}
