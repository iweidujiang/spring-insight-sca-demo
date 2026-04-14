package io.github.iweidujiang.scaorder.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 调用用户服务（sca-user），路径与 {@code UserController} 一致。
 */
@FeignClient("sca-user")
public interface UserFeignClient {

    @GetMapping("/user/score/{id}")
    Integer getScore(@PathVariable("id") Long id);

    @GetMapping("/user/addScore")
    Integer addScore(@RequestParam("id") Long id,
                     @RequestParam("lastScore") Integer lastScore,
                     @RequestParam("addScore") Integer addScore);
}
