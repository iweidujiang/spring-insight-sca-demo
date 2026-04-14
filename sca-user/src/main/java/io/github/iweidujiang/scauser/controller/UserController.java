package io.github.iweidujiang.scauser.controller;

import io.github.iweidujiang.scauser.feign.LoyaltyFeignClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 用户管理控制器
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private LoyaltyFeignClient loyaltyFeignClient;

    @GetMapping("/score/{id}")
    public Integer getScore(@PathVariable("id") Long id) {
        return loyaltyFeignClient.getScore(id);
    }

    @GetMapping("/addScore")
    public Integer addScore(@RequestParam("id") Long id,
                            @RequestParam("lastScore") Integer lastScore,
                            @RequestParam("addScore") Integer addScore) {
        return loyaltyFeignClient.addScore(id, lastScore, addScore);
    }

}
