package io.github.iweidujiang.scauser.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 积分服务 RPC
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@FeignClient("/sca-loyalty")
public interface LoyaltyFeignClient {

    @GetMapping("/score/{id}")
    Integer getScore(@PathVariable("id") Long id);

    @GetMapping("/addScore")
    Integer addScore(@RequestParam(value = "id") Long id,
                     @RequestParam(value = "lastScore") Integer lastScore,
                     @RequestParam(value = "addScore") Integer addScore);

}
