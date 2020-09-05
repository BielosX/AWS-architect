import com.beust.jcommander.Parameter;

public class CmdParams {
    @Parameter(names = {"-p", "--profile"}, description = "aws or local")
    public String profile;
}
