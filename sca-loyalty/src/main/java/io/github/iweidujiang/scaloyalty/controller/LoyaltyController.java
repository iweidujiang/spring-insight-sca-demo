package io.github.iweidujiang.scaloyalty.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 积分服务
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@Slf4j
@RestController
@RequestMapping("/loyalty")
public class LoyaltyController {

    /**
     * 获取用户当前积分
     * @param id 用户id
     */
    @GetMapping("/score/{id}")
    public Integer getScore(@PathVariable("id") Long id) {
        log.info("获取用户 id={} 当前积分", id);
        return 1800;
    }

    /**
     * 为当前用户增加积分
     * @param id 用户id
     * @param lastScore 用户当前积分
     * @param addScore 要增加的积分
     */
    @GetMapping("/addScore")
    public Integer addScore(@RequestParam(value = "id") Long id,
                            @RequestParam(value = "lastScore") Integer lastScore,
                            @RequestParam(value = "addScore") Integer addScore) {
        log.info("用户 id={} 增加 {} 积分", id, addScore);
        return lastScore + addScore;
    }

}
