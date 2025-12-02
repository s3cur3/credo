defmodule Credo.ConfigFileTest do
  use ExUnit.Case

  alias Credo.ConfigFile

  def assert_sorted_equality(
        %ConfigFile{files: files1, checks: checks1},
        {:ok, config_file2}
      ) do
    %ConfigFile{files: files2, checks: checks2} = config_file2

    assert files1 == files2
    assert_sorted_equality(checks1, checks2)
  end

  def assert_sorted_equality(checks1, checks2) do
    config1_sorted = checks1 |> Enum.sort()
    config2_sorted = checks2 |> Enum.sort()
    assert config1_sorted == config2_sorted
  end

  @default_config %ConfigFile{
    files: %{
      included: ["lib/", "src/", "web/"],
      excluded: []
    },
    checks: [
      {Credo.Check.Consistency.ExceptionNames},
      {Credo.Check.Consistency.LineEndings},
      {Credo.Check.Consistency.Tabs}
    ]
  }
  @example_config %ConfigFile{
    checks: [
      {Credo.Check.Design.AliasUsage},
      {Credo.Check.Design.TagFIXME},
      {Credo.Check.Design.TagTODO}
    ]
  }
  @example_config2 %ConfigFile{
    files: %{
      excluded: ["lib/**/*_test.exs"]
    },
    checks: [
      {Credo.Check.Consistency.ExceptionNames},
      {Credo.Check.Consistency.LineEndings},
      {Credo.Check.Consistency.Tabs}
    ]
  }
  @example_config3 %ConfigFile{
    files: %{
      included: ["lib/**/*.exs"]
    },
    checks: %{
      enabled: [
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Consistency.LineEndings},
        {Credo.Check.Consistency.Tabs}
      ],
      disabled: []
    }
  }

  test "merge works" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: []
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []},
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []}
        ],
        disabled: []
      }
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge({:ok, @default_config}, {:ok, @example_config})
    )
  end

  test "merge works /2" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: ["lib/**/*_test.exs"]
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ],
        disabled: []
      }
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge({:ok, @default_config}, {:ok, @example_config2})
    )
  end

  test "merge works /3" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/**/*.exs"],
        excluded: ["lib/**/*_test.exs"]
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ],
        disabled: []
      }
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge({:ok, @example_config2}, {:ok, @example_config3})
    )
  end

  test "merge works in the other direction, overwriting files[:excluded]" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: []
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ],
        disabled: []
      }
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge({:ok, @example_config2}, {:ok, @default_config})
    )
  end

  test "merge works in the other direction in reverse, NOT overwriting files[:excluded]" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/**/*.exs"],
        excluded: []
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ],
        disabled: []
      }
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge({:ok, @default_config}, {:ok, @example_config3})
    )
  end

  test "merge works with list" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: ["lib/**/*_test.exs"]
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []},
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []}
        ],
        disabled: []
      }
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge([{:ok, @default_config}, {:ok, @example_config2}, {:ok, @example_config}])
    )
  end

  test "merge_checks works" do
    base = %ConfigFile{
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    other = %ConfigFile{
      checks: [
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    expected = %{
      disabled: [],
      enabled: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "merge_checks works for map syntax %{} /1" do
    base = %ConfigFile{
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ]
      }
    }

    other = %ConfigFile{
      checks: %{
        extra: [
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []}
        ],
        disabled: [
          {Credo.Check.Consistency.Tabs, []}
        ]
      }
    }

    expected = %{
      enabled: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ],
      disabled: [
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "merge_checks works for map syntax %{} /2" do
    base = %ConfigFile{
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    other = %ConfigFile{
      checks: %{
        extra: [
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []},
          {Credo.Check.Consistency.Tabs, false}
        ]
      }
    }

    expected = %{
      disabled: [],
      enabled: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "merge_checks works for map syntax %{} /3" do
    base = %ConfigFile{
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    other = %ConfigFile{
      checks: %{
        extra: [
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []},
          {Credo.Check.Consistency.Tabs, false}
        ]
      }
    }

    expected = %{
      disabled: [],
      enabled: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "merge_checks works for map syntax %{} /4" do
    base = %ConfigFile{
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ]
      }
    }

    other = %ConfigFile{
      checks: %{
        enabled: [
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []},
          {Credo.Check.Consistency.Tabs, false}
        ]
      }
    }

    expected = %{
      disabled: [],
      enabled: [
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "merge_checks works for map syntax %{} /5" do
    base = %ConfigFile{
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []}
        ]
      }
    }

    other = %ConfigFile{
      checks: [
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    expected = %{
      disabled: [],
      enabled: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "merge_checks works for map syntax %{} /6" do
    base = %ConfigFile{
      checks: %{
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []},
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []}
        ]
      }
    }

    other = %ConfigFile{
      checks: %{
        disabled: [
          {Credo.Check.Consistency.Tabs, [force: :tabs]}
        ]
      }
    }

    expected = %{
      enabled: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ],
      disabled: [
        {Credo.Check.Consistency.Tabs, [force: :tabs]}
      ]
    }

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "loads .credo.exs from ./config subdirs in ascending directories as well" do
    dirs = ConfigFile.relevant_directories(".")

    config_subdir_count =
      dirs
      |> Enum.count(&String.ends_with?(&1, "config"))

    assert config_subdir_count > 1
  end

  test "loads broken config file and return error tuple" do
    exec = Credo.Execution.build([])
    config_file = Path.join([File.cwd!(), "test", "fixtures", "custom-config.exs.malformed"])

    result = ConfigFile.read_from_file_path(exec, ".", config_file)

    expected = {:error, {:badconfig, config_file, 9, "syntax error before: ", "checks"}}

    assert expected == result
  end

  test "loads config file and sets defaults" do
    exec = Credo.Execution.build([])
    config_file = Path.join([File.cwd!(), "test", "fixtures", "custom-config.exs"])
    config_name = "empty-config"

    {:ok, result} = ConfigFile.read_from_file_path(exec, ".", config_file, config_name)

    assert is_boolean(result.color)
    assert is_boolean(result.strict)
    assert is_integer(result.parse_timeout)
    assert is_list(result.files.included)
    assert not Enum.empty?(result.files.included)
    assert is_list(result.files.excluded)
    assert is_list(result.checks)
  end

  @tag :tmp_dir
  test "loads max_concurrent_check_runs from config file", %{tmp_dir: tmp_dir} do
    configured_value = 99

    config_content = """
    %{
      configs: [
        %{
          name: "default",
          max_concurrent_check_runs: #{configured_value},
          files: %{
            included: ["lib/"],
            excluded: []
          },
          checks: []
        }
      ]
    }
    """

    config_file_path = Path.join(tmp_dir, "max_concurrent_check_runs_test.exs")
    File.write!(config_file_path, config_content)

    try do
      exec = Credo.Execution.build([])
      {:ok, result} = ConfigFile.read_from_file_path(exec, ".", config_file_path)
      assert result.max_concurrent_check_runs == configured_value
    after
      File.rm_rf(tmp_dir)
    end
  end

  test "merge max_concurrent_check_runs correctly" do
    for base_value <- [nil, 4] do
      base = %ConfigFile{
        max_concurrent_check_runs: base_value,
        files: %{
          included: ["lib/"],
          excluded: []
        },
        checks: []
      }

      other = %{base | max_concurrent_check_runs: 99}

      {:ok, merged} = ConfigFile.merge({:ok, base}, {:ok, other})
      assert merged.max_concurrent_check_runs == other.max_concurrent_check_runs
    end
  end

  test "merge max_concurrent_check_runs preserves base when other is invalid" do
    for new_value <- [nil, -1, 0] do
      base = %ConfigFile{
        max_concurrent_check_runs: 4,
        files: %{
          included: ["lib/"],
          excluded: []
        },
        checks: []
      }

      other = %{base | max_concurrent_check_runs: new_value}

      {:ok, merged} = ConfigFile.merge({:ok, base}, {:ok, other})
      assert merged.max_concurrent_check_runs == base.max_concurrent_check_runs
    end
  end

  @tag :tmp_dir
  test "on invalid max_concurrent_check_runs, defaults to schedulers_online", %{tmp_dir: tmp_dir} do
    try do
      for configured_value <- [nil, 0, -1, "not_an_int"] do
        config_content = """
        %{
          configs: [
            %{
              name: "default",
              max_concurrent_check_runs: #{inspect(configured_value)},
              files: %{
                included: ["lib/"],
                excluded: []
              },
              checks: []
            }
          ]
        }
        """

        config_file_path = Path.join(tmp_dir, "max_concurrent_check_runs_test.exs")
        File.write!(config_file_path, config_content)

        exec = Credo.Execution.build([])
        {:ok, result} = ConfigFile.read_from_file_path(exec, ".", config_file_path)
        assert result.max_concurrent_check_runs == System.schedulers_online() * 4
      end
    after
      File.rm_rf(tmp_dir)
    end
  end

  test "max_concurrent_check_runs defaults to 4 * System.schedulers_online() when not specified" do
    exec = Credo.Execution.build([])
    config_file = Path.join([File.cwd!(), "test", "fixtures", "custom-config.exs"])
    config_name = "empty-config"

    {:ok, result} = ConfigFile.read_from_file_path(exec, ".", config_file, config_name)
    assert result.max_concurrent_check_runs == System.schedulers_online() * 4
  end
end
