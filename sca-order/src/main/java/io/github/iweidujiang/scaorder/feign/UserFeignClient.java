package io.github.iweidujiang.scaorder.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 用户服务 RPC
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@FeignClient("sca-user")
public interface UserFeignClient {

    @GetMapping("/score/{id}")
    Integer getScore(@PathVariable("id") Long id);

    @GetMapping("/addScore")
    Integer addScore(@RequestParam Long id,
                            @RequestParam Integer lastScore,
                            @RequestParam Integer addScore);
}
