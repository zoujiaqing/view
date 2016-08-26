import std.stdio;
import std.regex;
import std.conv;
import std.algorithm;

struct CodeBlock
{
	string name;
	string code;

	bool isTag = true;

	bool single = false;
	bool effective = true;
	bool openning = true;

	size_t startLength = 0;
	size_t endLength = 0;

	string frontCode;
	string bodyCode;

	string[] vars;
}

struct VarBlock
{
	string name;
	CodeBlock codeBlock;
}

class Parser
{
	private
	{
		int _count = 0;
		CodeBlock[int] _codeBlocks;
		string[] _tags = ["if", "for"];

		string backCode;
		string frontCode;
	}

	private void addBlock(CodeBlock block)
	{
		this._codeBlocks[this._count] = block;
		this._count++;
	}

	void openTag(T, DI = size_t)(Captures!(T, DI) cap)
	{
		writeln(cap[2] ~ " is open!");

		backCode = cap.post;

		CodeBlock block;
		block.name = cap[2];
		block.code = cap.hit;
		block.bodyCode = cap.hit;

		int preCount = this._count-1;

		block.frontCode = cap.pre;
		block.startLength = cap.pre.length;
		block.endLength = cap.pre.length + cap.hit.length;

		if (preCount >= 0)
		{
			block.frontCode = cap.pre[this._codeBlocks[preCount].endLength..$];
		}

		this.addBlock(block);

		if (!this._tags.canFind(cap[2]))
		{
			block.effective = false;
			block.openning = false;
			writeln("cant support tag :" ~ cap[2]);
		}
	}

	void closeTag(T, DI = size_t)(Captures!(T, DI) cap)
	{
		bool matched = false;

		writeln(cap[2] ~ " is end! ");
		// 从最后匹配到的标签中查找配对的
		for (int i = this._count-1; i >= 0; i--)
		{
			writeln("preTag is : " ~ this._codeBlocks[i].name);
			// writeln("openning is : " ~ (this._codeBlocks[i].openning ? "yes" : "no"));
			// writeln("effective is : " ~ (this._codeBlocks[i].effective ? "yes" : "no"));
			// 是否配对，并且是未关闭，并且是有效的标签
			if (this._codeBlocks[i].name == cap[2] && this._codeBlocks[i].openning && this._codeBlocks[i].effective)
			{
				// 被配对标签内部所有代码
				string blockCode = "";

				matched = true;

				size_t sl = 0;
				// 如果最后一个标签就配对不需要循环处理两个标签中间的标签
				if (i < this._count)
				{
					int nextCount = i+1;

					writefln(cap[2] ~ " nextCount: %s", nextCount);
					
					if (nextCount < this._count && nextCount == i+1)
					{
						sl = this._codeBlocks[nextCount].startLength;
					}

					// 从匹配到的标签往后都删除
					for (int j = nextCount; j < this._count; j++)
					{
						// writeln(this._codeBlocks[j].name ~ " J frontCode: " ~ this._codeBlocks[j].frontCode);
						// writeln(this._codeBlocks[j].name ~ " J bodyCode: " ~ this._codeBlocks[j].bodyCode);

						blockCode ~= this._codeBlocks[j].frontCode;
						blockCode ~= this._codeBlocks[j].bodyCode;

						this._codeBlocks.remove(j);
					}

					this._count = nextCount;
				}

				if (sl == 0)
				{
					blockCode ~= cap.pre[this._codeBlocks[i].endLength..$];
				}
				else
				{
					blockCode ~= cap.pre[this._codeBlocks[i].endLength..sl];
				}

				blockCode = "
				<" ~ this._codeBlocks[i].name ~ ">
				" ~ blockCode ~ "
				</" ~ this._codeBlocks[i].name ~ ">
				";


				this._codeBlocks[i].bodyCode = blockCode;
				this._codeBlocks[i].openning = false;
				this._codeBlocks[i].endLength = cap.pre.length + cap.hit.length;


				writeln(this._codeBlocks[i].name ~ " bodyCode: " ~ this._codeBlocks[i].bodyCode);

				// 处理完匹配的了就可以跳出这块代码进行下一个标签处理了
				blockCode = "";
				break;
			}
			else
			{
				if (this._codeBlocks[i].openning)
				{
					this._codeBlocks[i].bodyCode = this._codeBlocks[i].code;
				}
			}
			continue;
		}

		// 如果匹配到了，后面的代码往后窜
		if(matched)
		{
			backCode = cap.post;
		}
	}

	public string parse(string template_content, int node = 0)
	{
		// 清理注释
		template_content = this.cleanComment(template_content);

		foreach(cap; this.findAll(template_content))
		{
			if (cap.length == 0)
			{
				writeln("not match!");
				continue;
			}

			// 如果是结束标签就寻找之前匹配到的标签进行配对
			if(cap[1] == "end")
			{
				this.closeTag(cap);
			}
			else
			{
				this.openTag(cap);
			}
		}

		string resultContent = "";
		for (int i = 0; i < this._count; i++)
		{
			resultContent ~= this._codeBlocks[i].frontCode;
			resultContent ~= this._codeBlocks[i].bodyCode;
		}
		
		resultContent ~= backCode;

		return resultContent;
	}

	public auto findAll(string code)
	{
		return matchAll(code, regex(`\{%[\s\n]+?(end)?(\w+)([^\n\}\{\}]+)?[\s\n]+?%\}`));
	}

	public string parseIfStatement(string condition, string text)
	{
		CodeBlock block;
		block.name = "if";
		// TODO
		return text;
	}

	public string parseForStatement(string condition, string text)
	{
		// TODO
		return text;
	}

	private string cleanComment(string code)
	{
		return replaceAll(code, regex(`\{#[\s\n\S]+?#\}\s+?\n?`), "\n");
	}

	private string replaceVers(string code)
	{
		//foreach(result; matchAll(template_content, regex(`\{\{\s+?[\w\._]+\s+?\}\}`)))
		//	writeln(result.hit);
		return code;
	}
}

void main()
{
     string template_content = "<h1>{{ title }}</h1>
		<ul>
		{# this is comment #}
		{% if title == '' %}
		{% if title == '' %}
		{% if title == '' %}
		{% fi title == '' %}
		{% if title == '' %}
		{% for user in users %}
			{# this is comment #}
			<li>{{ title }} {{ user.id }} {{ user.name }} {{ user.email }}</li>
		{% endfor %}
		{% endif %}
		{# this is comment #}
		</ul>
	";

	Parser p = new Parser;
	writeln("All code: \n" ~ p.parse(template_content));
}
