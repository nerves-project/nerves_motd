defmodule NervesMOTD.FirmwareNicknameTest do
  use ExUnit.Case

  alias NervesMOTD.FirmwareNickname

  test "converts UUIDs" do
    # These all came from fwup unit tests
    assert "present-snack" ==
             FirmwareNickname.uuid_to_nickname("b3c560af-d052-58c1-228d-5fa869817cda")

    assert "energy-bid" ==
             FirmwareNickname.uuid_to_nickname("53233641-82a4-5576-b75d-d227a234c626")

    assert "visa-present" ==
             FirmwareNickname.uuid_to_nickname("ecb37e6e-6a7b-5f22-2077-7ccad0e40d85")
  end
end
