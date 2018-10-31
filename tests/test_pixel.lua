require('src/test')
require('src/core')
require('src/builtins')
require('src/contextlib')
require('src/itertools')
require('src/logic')
require('src/objects')
require('src/pixel')
require('src/screen')
require('src/string')
require('src/system')


fixture('pixels', function(monkeypatch) 
  local pixels = list{
    Pixel(10, 10, 10),
    Pixel(20, 20, 20),
    Pixel(30, 30, 30),
    Pixel(40, 40, 40),
  }
  local function _getColor(x, y) 
    for p in iter(pixels) do if p.x == x and p.y == y then return p.expected_color end end
  end
  local function _getColors(pos) 
    local colors = list()
    for p in iter(pos) do colors:append(_getColor(p[1], p[2])) end
    return colors
  end

  monkeypatch.setattr('getColor', _getColor)
  monkeypatch.setattr('getColors', _getColors)
  return pixels
end)


describe('pixel - Pixel', 

  it('can create and hash pixel objects', function() 
    local pixels = set()
    local length = 0
    for i=1, 1000, 100 do
      for j=1, 1000, 100 do
        for color=1, 100000, 10000 do
          pixels:add(Pixel(i, j, color))
          assert(len(pixels) == length + 1, 'Did not create unique pixel')
          length = length + 1
        end
      end
    end
  end),

  it('can add and subtract pixel objects', function()
    local pix = Pixel(10, 10, 10) 
    local added = pix + Pixel(10, 10)
    local subbed = pix - Pixel(10, 10)
    assert(added:isinstance(Pixel), 'Adding pixel objects did not return pixel')
    assert(subbed:isinstance(Pixel), 'Subtracting pixel objects did not return pixel')
    assert(added.x == 20 and added.y == 20, 'Did not add pixel positions correctly')
    assert(subbed.x == 0 and subbed.y == 0, 'Did not add pixel positions correctly')
    assert(pix.expected_color == added.expected_color, 'Changed pixel color on add')
    assert(pix.expected_color == subbed.expected_color, 'Changed pixel color on sub')
    local added_table = pix + {10, 10}
    local subbed_table = pix - {10, 10}
    assert(added:isinstance(Pixel), 'Adding pixel and table did not return pixel')
    assert(subbed:isinstance(Pixel), 'Subtracting pixel and table did not return pixel')
    assert(added_table.x == 20 and added_table.y == 20, 'Did not add pixel positions correctly')
    assert(subbed_table.x == 0 and subbed_table.y == 0, 'Did not add pixel positions correctly')
    assert(pix.expected_color == added_table.expected_color, 'Changed pixel color on add with table')
    assert(pix.expected_color == subbed_table.expected_color, 'Changed pixel color on sub with table')
  end),

  it('can evaluate pixel equality', function(pixels) 
    assert(Pixel(10, 10, 10) == Pixel(10, 10, 10), 'Equal pixels not equal')
    assert(Pixel(0, 10, 10) ~= Pixel(10, 10, 10), 'Non-equal pixels equal')
    assert(Pixel(10, 0, 10) ~= Pixel(10, 10, 10), 'Non-equal pixels equal')
    assert(Pixel(10, 10, 0) ~= Pixel(10, 10, 10), 'Non-equal pixels equal')
  end),
  
  it('can stringify pixel', function() 
    assert(tostring(Pixel(10, 10, 10)) == string.format('<Pixel(%d, %d)>', 10, 10), 'Pixel tostring not correct')
  end),

  it('can get color of pixel', function(pixels)
    assert(Pixel(10, 10).color == 10, 'Did not get color of pixel') 
  end),

  it('can detect pixel color change', function(pixels) 
    local pix = Pixel(10, 10)
    local changed = pix:color_changed()
    assert(not changed(), 'Detected change in color when there was none')
    assert(not changed(), 'Detected change in color when there was none')
    pixels[1].expected_color = 10000
    assert(changed(), 'Did not detect change in pixel color')
    assert(not changed(), 'Detected change in color when there was none')
  end),

  it('can detect pixel visibility', function(pixels) 
    assert(Pixel(10, 10, 10):visible(), 'Visible pixel not visible') 
    assert(not Pixel(0, 10, 10):visible(), 'Non visible pixel visible') 
    assert(not Pixel(10, 0, 10):visible(), 'Non visible pixel visible') 
    assert(not Pixel(10, 10, 0):visible(), 'Non visible pixel visible') 
  end)
)


describe('pixel - Pixels',

  it('can add and subtract Pixels objects', function() 
    local pixels = Pixels{Pixel(0, 0), Pixel(10, 10), Pixel(10, 10)}
    local added = pixels + Pixels{Pixel(10, 10), Pixel(20, 20)}
    local subbed = pixels - Pixels{Pixel(10, 10), Pixel(20, 20)}
    assert(added:isinstance(Pixels), 'Add did not return Pixels object')
    assert(subbed:isinstance(Pixels), 'Subtract did not return Pixels object')
    assert(len(pixels.pixels) == 2, 'Did not create pixels correctly')
    assert(len(added.pixels) == 3, 'Did not add pixels correctly')
    assert(len(subbed.pixels) == 1, 'Did not sub pixels correctly')
  end),

  it('can evaluate Pixels equality', function() 
    assert(Pixels{Pixel(10, 10)} == Pixels{{10, 10}, {10, 10}}, 'Pixels are not equal')
    assert(Pixels{Pixel(10, 10)} == Pixels{Pixel(10, 10)}, 'Equal Pixels objects are not equal')
    assert(Pixels{Pixel(10, 10)} ~= Pixels{Pixel(10, 10), Pixel(10, 20)}, 'Not equal Pixels objects are equal')
    assert(Pixels{Pixel(0, 10)} ~= Pixels{Pixel(10, 10)}, 'Not equal Pixels objects are equal')
  end),

  it('can stringify Pixels', function() 
    local pixels = Pixels{Pixel(10, 10), Pixel(20, 20)}
    assert(tostring(pixels) == string.format('<Pixels(n=%d)>', len(pixels.pixels)))
  end),

  it('can get colors of Pixels', function(pixels) 
    local pix = Pixels{Pixel(10, 10, 10), Pixel(20, 20, 20)}
    local expected = {pixels[1].expected_color, pixels[2].expected_color}
    assert(requal(pix.colors, expected), 'Did not get all correct colors of Pixels')
  end),

  it('can detect Pixels visibility', function(pixels) 
    assert(Pixels{Pixel(10, 10, 10), Pixel(20, 20, 20)}:visible(), 'Visible pixel is not visible')
    assert(not Pixels{Pixel(10, 10, 0), Pixel(20, 20, 20)}:visible(), 'Non visible pixel is visible')
  end),

  it('can count number of different pixels', function(pixels) 
    local pix = Pixels{Pixel(10, 10, 10), Pixel(20, 20, 20), Pixel(100, 100, 10), Pixel(200, 200, 20)}
    assert(pix:count() == 2, 'Did not get correct pixel count')
  end),

  it('can detect specific Pixels color change configurations', function(pixels) 
    local pix = Pixels{
      Pixel(10, 10),
      Pixel(20, 20),
      Pixel(30, 30),
      Pixel(40, 40)
    }
    local any_change = pix:any_colors_changed()
    local all_change = pix:all_colors_changed()
    local two_change = pix:n_colors_changed(2)
    assert(not any_change(), 'Detected change when there was not one')
    assert(not all_change(), 'Detected change when there was not one')
    assert(not two_change(), 'Detected change when there was not one')
    pixels[1].expected_color = 0
    assert(any_change(), 'Did not detect change')
    assert(not all_change(), 'Detected change when there was not one')
    assert(not two_change(), 'Detected change when there was not one')
    pixels[1].expected_color = 1000
    pixels[2].expected_color = 1000
    assert(any_change(), 'Did not detect change')
    assert(not all_change(), 'Detected change when there was not one')
    assert(two_change(), 'Did not detect change')
    pixels[3].expected_color = 1000000
    pixels[4].expected_color = 1000000
    pixels[3].expected_color = 1000000
    pixels[4].expected_color = 1000000
    assert(any_change(), 'Did not detect change')
    assert(all_change(), 'Did not detect change')
    assert(two_change(), 'Did not detect change')
  end)
)

-- TODO: Triangle tests

describe('pixel - Region',

  it('can add and subtract Region objects', function() 
    local region = Region{Pixel(0, 0), Pixel(10, 10)}
    local added = region + Region{Pixel(10, 10), Pixel(20, 20)}
    local subbed = region - Region{Pixel(10, 10), Pixel(20, 20)}
    assert(added:isinstance(Region), 'Add did not return Region object')
    assert(subbed:isinstance(Region), 'Subtract did not return Region object')
    assertRaises('Can only', function() 
      local fail = Region{Pixel(0, 0)} + Pixels{Pixel(10, 10)}
    end, 'Adding Region to pixels did not fail')
    assertRaises('Can only', function() 
      local fail = Region{Pixel(0, 0)} - Pixels{Pixel(10, 10)}
    end, 'Subtracting Region to pixels did not fail')
  end),

  it('can stringify Region', function() 
    local region = Region{Pixel(0, 0), Pixel(10, 10)}
    assert(tostring(region) == string.format('<Region(pixels=%d, color=%d)>', len(region.pixels), region.color))
  end),

  it('can get center of Region', function() 
    local region = Region{Pixel(0, 0), Pixel(10, 10)}
    assert(region.center == Pixel(5, 5), 'Did not get correct center of region')
  end),
  
  it('can create Ellipse', function() 
    local ellipse = Ellipse{x=0, y=0, width=20, height=20, spacing=20}
    assert(tostring(ellipse) == '<Ellipse(0, 0, width=20, height=20, spacing=20, color=16777215, pixels=152)>', 'Did not create correct ellipse')
  end),
  
  it('can create Rectangle', function() 
    local rect = Rectangle{
      x=10,
      y=10,
      width=100,
      height=100,
      spacing=10
    }
    assert(rect.x == 10, 'Rectangle has incorrect x')
    assert(rect.y == 10, 'Rectangle has incorrect y')
    assert(rect.width == 100, 'Rectangle has incorrect width')
    assert(rect.height == 100, 'Rectangle has incorrect height')
    assert(rect.spacing == 10, 'Rectangle has incorrect spacing')
    assert(len(rect.pixels) == 121, 'Incorrect number of pixels in Rectangle')
    assert(rect.pixels[1].x == rect.x and rect.pixels[1].y == rect.y, 'Incorrect first pixel location')
    assert(rect.pixels[-1].x == rect.x + rect.width and rect.pixels[-1].y == rect.y + rect.height, 'Incorrect last pixel location')
    assert(tostring(rect) == '<Rectangle(10, 10, width=100, height=100, spacing=10, color=16777215, pixels=121)>', 'Did not create correct rectangle')
  end),
  
  sit('can create Triangle', function() 
    local triangle = Triangle{x=0, y=0}
    assert(tostring(triangle) == '<Triangle(0, 0, spacing=, color=16777215, pixels=)>', 'Did not create correct triangle')
  end)
  
)


run_tests()
