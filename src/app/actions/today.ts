'use server'

import { getTodayCockpit as _getTodayCockpit } from '@/lib/queries/today'

export async function getTodayCockpitAction(
  ...args: Parameters<typeof _getTodayCockpit>
) {
  return _getTodayCockpit(...args)
}
