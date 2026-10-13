package io.github.iweidujiang.scauser.jdbc;

/**
 * H2 {@code CREATE ALIAS} 目标：单签名静态方法，避免绑定 {@link Thread#sleep} 重载失败。
 *
 * @since 2026-10-12
 * @author 公众号：苏渡苇 GitHub：https://github.com/iweidujiang
 */
public final class DemoH2Functions {

    private DemoH2Functions() {
    }

    /**
     * @param millis 休眠毫秒
     * @throws InterruptedException 中断
     */
    public static void sleepMs(long millis) throws InterruptedException {
        Thread.sleep(Math.max(0L, millis));
    }
}
