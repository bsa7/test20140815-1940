require 'colorize'

#---------------------------------------------------------------------------------------------
def pop_good_groups_by_rules order, gift_groups

  order_original = order.clone

  # 1. Если одновременно выбраны А и B, то их суммарная стоимость уменьшается на 10% (для каждой пары А и B)
  if order["A"].exists? && order["B"].exists?
    make_rule_gift order, gift_groups, ["A", "B"], 0.1
    return
  end

  # 2. Если одновременно выбраны D и E, то их суммарная стоимость уменьшается на 5% (для каждой пары D и E)
  if order["D"].exists? && order["E"].exists?
    make_rule_gift order, gift_groups, ["D", "E"], 0.05
    return
  end

  # 3. Если одновременно выбраны E,F,G, то их суммарная стоимость уменьшается на 5% (для каждой тройки E,F,G)
  if order["E"].exists? && order["F"].exists? && order["G"].exists?
    make_rule_gift order, gift_groups, ["E", "F", "G"], 0.05
    return
  end

  # 4. Если одновременно выбраны А и один из [K,L,M], то стоимость выбранного продукта уменьшается на 5%
  if order["A"].exists? && (order["K"].exists? || order["L"].exists? || order["M"].exists?)
    if order["K"].exists?
      make_rule_gift order, gift_groups, ["A", "K"], 0.05
    elsif order["L"].exists?
      make_rule_gift order, gift_groups, ["A", "L"], 0.05
    elsif order["M"].exists?
      make_rule_gift order, gift_groups, ["A", "M"], 0.05
    end
    return
  end

  total_count = 0
  total_cost = 0
  total_gift = {}
  order.each do |good_name, count|
    #### 9. Продукты A и C не участвуют в скидках 5,6,7
    unless ["A","C"].include?(good_name) || count <= 0
      total_count += count
      total_cost += count * $goods[good_name][:price]
      total_gift[good_name] = count
    end
  end

  # 5. Если пользователь выбрал одновременно 3 продукта, он получает скидку 5% от суммы заказа
  if total_count == 3
    make_count_gift order, gift_groups, total_gift, total_cost, 0.05

  # 6. Если пользователь выбрал одновременно 4 продукта, он получает скидку 10% от суммы заказа
  elsif total_count == 4
    make_count_gift order, gift_groups, total_gift, total_cost, 0.1

  # 7. Если пользователь выбрал одновременно 5 продуктов, он получает скидку 20% от суммы заказа
  elsif total_count >= 5
    make_count_gift order, gift_groups, total_gift, total_cost, 0.2
  end

  #### 8. Описанные скидки 5,6,7 не суммируются, применяется только одна из них
  ####10. Каждый товар может участвовать только в одной скидке. Скидки применяются последовательно в порядке описанном выше.
end

#---------------------------------------------------------------------------------------------
def make_count_gift(order, gift_groups, total_gift, total_cost, percentage)
  total_gift.each do |good_name, count|
    order[good_name] -= count
  end
  total_gift[:gift] = (total_cost * percentage).round(2)
  gift_groups << total_gift
end

#---------------------------------------------------------------------------------------------
def make_rule_gift order, gift_groups, goods_by_rule, percentage
  gift_hash = goods_by_rule.each_with_object({}){|r, h|h[r] = 1}
  good_prices = 0
  goods_by_rule.each do |good_name|
    good_prices += $goods[good_name][:price]
  end
  gift_hash[:gift] = (good_prices * percentage).round(2)
  gift_groups << gift_hash
  goods_by_rule.each do |good_name|
    order[good_name] -= 1
  end
end

#---------------------------------------------------------------------------------------------------------------------------------------
def order_string good_name, quantity, unit_price
  "#{good_name.to_s.rjust(16)} | #{quantity.to_s.rjust(8)} | #{unit_price.to_s.rjust(10)} | #{(quantity * unit_price).round(2).to_s.rjust(10)}"
end

#-------------------------------
class Float
  def exists?
    self > 0
  end
end

#-------------------------------
class Fixnum
  def exists?
    self > 0
  end
end

#-------------------------------
class NilClass
  def exists?
    false
  end
end


#---------------------------------------------------------------------------------------------------------------------------------------
$goods = {
 "A" => {price: 10.11},
 "B" => {price: 11.12},
 "C" => {price: 13.14},
 "D" => {price: 15.16},
 "E" => {price: 17.18},
 "F" => {price: 19.20},
 "G" => {price: 21.22},
 "H" => {price: 23.24},
 "I" => {price: 25.26},
 "J" => {price: 27.28},
 "K" => {price: 29.30},
 "L" => {price: 31.32},
 "M" => {price: 33.34}
}

orders = {
 "Order # 1" => {"A" => 2, "B" => 1, "K" => 2, "M" => 3},
 "Order # 2" => {"B" => 2, "C" => 1, "D" => 1, "E" => 3, "F" => 5, "G" =>2},
 "Order # 3" => {"A" => 2, "C" => 1, "D" => 1, "E" => 3, "F" => 5, "G" =>3},
 "Order # 4" => {"A" => 4, "K" => 1, "L" => 2, "B" => 1, "C" => 5, "F" =>3, "M" => 3, "D" => 7, "E" => 5, "F" => 3, "G" => 3}
}

orders.each do |order_name, order|
  order_stub = order.clone
  gift_groups = []

  while true do
    order_backup = order_stub.clone
    pop_good_groups_by_rules order_stub, gift_groups
    break if order_backup == order_stub
  end

  puts "================= #{order_name.center(17)} =================".yellow
  puts "Good description | Quantity | Unit Price | Line Total"
  order_stub = order.clone
  gift_groups.each do |gift|
    gift.each do |key, value|
      if key == :gift
        puts "Gift: #{value}".rjust(53).green
      else
        order_stub[key] -= 1
        puts order_string(key, value, $goods[key][:price])
      end
    end
  end
  order_stub.delete_if{|key, value|value <= 0}
  order_stub.each do |good_name, count|
    puts order_string good_name, count, $goods[good_name][:price]
  end
  puts "================= #{'Total'.center(17)} =================".yellow
  grand_total = order.each_with_object([]){|(key, value), gt| gt << $goods[key][:price] * value}.inject{|sum,x| sum + x }.round(2)
  puts "Total (without gifts): #{sprintf('%.2f', grand_total)}".rjust(53)
  gift_total = gift_groups.map{|x|x[:gift]}.inject{|sum,x| sum + x }.round(2)
  puts "Gift total: #{sprintf('%.2f', gift_total)}".rjust(53).green
  puts "Grand total: #{sprintf('%.2f', grand_total - gift_total)}".rjust(53).yellow

  puts "\n\n"
end

