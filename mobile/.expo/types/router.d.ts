/* eslint-disable */
import * as Router from 'expo-router';

export * from 'expo-router';

declare module 'expo-router' {
  export namespace ExpoRouter {
    export interface __routes<T extends string = string> extends Record<string, unknown> {
      StaticRoutes: `/` | `/(auth)/login` | `/(auth)/register` | `/(cause)/dashboard` | `/(cause)/settings` | `/(customer)/impacto` | `/(restaurant)/dashboard` | `/(restaurant)/donations` | `/(restaurant)/menu` | `/(restaurant)/orders` | `/(restaurant)/settings` | `/_sitemap` | `/dashboard` | `/donations` | `/impacto` | `/login` | `/menu` | `/orders` | `/register` | `/settings`;
      DynamicRoutes: never;
      DynamicRouteTemplate: never;
    }
  }
}
