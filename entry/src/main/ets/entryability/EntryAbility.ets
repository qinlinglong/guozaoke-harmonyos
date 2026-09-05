/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DEFAULT_THEME_COLOR, normalizeThemeColor } from '../util/ThemeUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Use one edge-to-edge window for every route. Page roots consume the
    // measured avoid-area values so controls stay clear of system gestures.
    windowStage.getMainWindow().then((mainWindow: window.Window) => {
      mainWindow.setWindowLayoutFullScreen(true);
      mainWindow.setWindowSystemBarEnable(['status', 'navigation']);
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: DEFAULT_THEME_COLOR,
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: DEFAULT_THEME_COLOR,
        navigationBarContentColor: '#FFFFFF'
      });
    }).catch((err: Error) => {
      hilog.warn(DOMAIN, 'testTag', 'Failed to configure immersive bars: %{public}s', JSON.stringify(err));
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      // PersistentStorage depends on an initialized UI instance. Calling it
      // from onCreate silently fails on HarmonyOS 6; the loadContent callback
      // is the first supported lifecycle point.
      PersistentStorage.persistProp('commentsOrderDesc', false);
      PersistentStorage.persistProp('imageBedApiKey', '');
      PersistentStorage.persistProp('themeColor', DEFAULT_THEME_COLOR);
      PersistentStorage.persistProp('selfProfileCache', '');
      AppStorage.setOrCreate('safeAreaTop', 0);
      AppStorage.setOrCreate('safeAreaBottom', 0);
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      const uiContext = mainWindow.getUIContext();
      const updateAvoidArea = (): void => {
        try {
          const systemArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
          AppStorage.setOrCreate('safeAreaTop', uiContext.px2vp(systemArea.topRect.height));
        } catch (_) { }
        try {
          const navigationArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
          AppStorage.setOrCreate('safeAreaBottom', uiContext.px2vp(navigationArea.bottomRect.height));
        } catch (_) { }
      };
      updateAvoidArea();
      mainWindow.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('safeAreaTop', uiContext.px2vp(data.area.topRect.height));
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('safeAreaBottom', uiContext.px2vp(data.area.bottomRect.height));
        }
      });
      const storedTheme: string = normalizeThemeColor(AppStorage.get<string>('themeColor') ?? '') || DEFAULT_THEME_COLOR;
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: storedTheme,
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: storedTheme,
        navigationBarContentColor: '#FFFFFF'
      });
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
