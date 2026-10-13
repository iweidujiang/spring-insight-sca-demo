CREATE TABLE IF NOT EXISTS demo_item (
    id    BIGINT PRIMARY KEY,
    name  VARCHAR(64) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 供慢 SQL 造数：须单签名方法（Thread.sleep 有重载，H2 会建别名失败）
CREATE ALIAS IF NOT EXISTS SLEEP_MS FOR "io.github.iweidujiang.scauser.jdbc.DemoH2Functions.sleepMs";
